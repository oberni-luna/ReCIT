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

    @Bindable var transaction: UserTransaction
    @State var message: String = ""
    /// The transition to apply on submit, or `nil` to just send a message.
    let transition: TransactionTransition?

    private var isMessageRequired: Bool {
        transition?.requiresMessage ?? false
    }

    private var isSubmitDisabled: Bool {
        isMessageRequired && message.isEmpty
    }

    private var submitLabel: String {
        transition?.event.label ?? String(localized: "action.send_message")
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
            Form {
                Section { } header: {
                    Text(.transactionFormHeader(transaction.item.edition?.title ?? "", transaction.owner.username))
                        .textStyle(.title50)
                        .foregroundStyle(.foregroundDefault)
                }
                
                if transaction._id.isEmpty {
                    Section {
                        Picker("transaction.form.type", selection: $transaction.type) {
                            ForEach(TransactionType.allCases.filter { $0 != .inventorying }, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: .xSmall) {
                        TextEditor(text: $message)
                            .frame(minHeight: 48)
                            .withLabel(label: isMessageRequired ? "transaction.form.your_message_required" : "transaction.form.your_message")
                    }
                }
                .listRowSeparator(.visible)
                .listSectionSeparator(.hidden)

                if let user = userModel.myUser {
                    Section {} footer: {
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
                    .listRowSeparator(.visible)
                    .listSectionSeparator(.hidden)
                }
            }
            .applyListBackground()
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
