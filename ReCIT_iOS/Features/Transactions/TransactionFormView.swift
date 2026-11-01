//
//  TransactionFormView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 30/11/2025.
//

import SwiftUI
import LBSnackBar
import SwiftData

struct TransactionFormView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    @Environment(\.snackBar) private var snackBar
    @Environment(UserModel.self) var userModel
    @Environment(TransactionModel.self) var transactionModel

    let transaction: UserTransaction
    @State var message: String = ""
    /// The transition to apply on submit, or `nil` to just send a message.
    let transition: TransactionTransition?

    /// A transaction not yet on the server: the form is asking for the copy, and its words follow
    /// the copy's status — the type is the item's, inventaire.io offers no choice.
    private var isRequest: Bool {
        transaction._id.isEmpty
    }

    private var isMessageRequired: Bool {
        transition?.requiresMessage ?? false
    }

    private var isSubmitDisabled: Bool {
        isMessageRequired && message.isEmpty
    }

    private var title: String {
        let book: String = transaction.item.edition?.title ?? ""
        return isRequest
            ? String(localized: transaction.type.requestTitle(book: book, owner: transaction.owner.username))
            : String(localized: .transactionFormHeader(book, transaction.owner.username))
    }

    private var messageLabel: String {
        if isRequest { return String(localized: transaction.type.requestMessageLabel) }
        return isMessageRequired
            ? String(localized: "transaction.form.your_message_required")
            : String(localized: "transaction.form.your_message")
    }

    private var submitLabel: String {
        if isRequest { return String(localized: transaction.type.requestButtonLabel) }
        return transition?.event.label ?? String(localized: "action.send_message")
    }

    /// Applies the picked transition through the state machine, or sends a plain
    /// message when there is no transition, surfacing any failure via the snackbar.
    private func submit(user: User) async {
        do {
            if let transition {
                try await transactionModel.perform(
                    event: transition.event,
                    on: transaction,
                    message: message,
                    author: user,
                    modelContext: modelContext
                )
            } else {
                try transactionModel.postMessageOptimistic(
                    transaction: transaction,
                    message: message,
                    author: user,
                    modelContext: modelContext
                )
            }
            dismiss()
        } catch {
            snackBar.show { SnackBarView.error(error) }
        }
    }

    var body: some View {
        NavigationStack {
            DesignSystem.Form {
                Section { } header: {
                    VStack(alignment: .leading, spacing: .small) {
                        Text(title)
                            .textStyle(.title50)
                            .foregroundStyle(.foregroundDefault)
                        if isRequest {
                            Text(.init(String(localized: transaction.type.requestSentence(owner: transaction.owner.username))))
                                .textStyle(.content300)
                                .foregroundStyle(.foregroundSecondary)
                        }
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: .xSmall) {
                        TextEditor(text: $message)
                            .frame(minHeight: 48)
                            .withLabel(label: messageLabel)
                    }
                }
                .listRowSeparator(.visible)
                .listSectionSeparator(.hidden)
            }
            .formActionBar {
                if let user = userModel.myUser {
                    AsyncButton(
                        action: { await submit(user: user) },
                        actionOptions: [.showProgressView],
                        label: {
                            Text(submitLabel)
                                .frame(maxWidth: .infinity)
                        }
                    )
                    .buttonStyle(.primary())
                    .frame(maxWidth: .infinity)
                    .disabled(isSubmitDisabled)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action.close", systemImage: "xmark") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ListFormView()
}
