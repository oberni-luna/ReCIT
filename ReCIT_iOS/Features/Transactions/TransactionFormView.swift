//
//  TransactionFormView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 30/11/2025.
//

import SwiftUI
import LBSnackBar

struct TransactionFormView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    @Environment(\.snackBar) private var snackBar
    @EnvironmentObject var userModel: UserModel
    @EnvironmentObject var transactionModel: TransactionModel

    @Bindable var transaction: UserTransaction
    @State var message: String = ""

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
                            ForEach(TransactionType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: .xSmall) {
                        TextEditor(text: $message)
                            .frame(minHeight: 48)
                            .withLabel(label: "transaction.form.your_message")
                    }
                }
                .listRowSeparator(.visible)
                .listSectionSeparator(.hidden)

                if let user = userModel.myUser {
                    Section {} footer: {
                        if let nextActions = transaction.nextAvailableState(for: user) {
                            HStack {
                                ForEach(nextActions, id: \.self) { nextAction in
                                    AsyncButton(action: {
                                        do {
                                            switch nextAction {
                                            case .requested:
                                                try await transactionModel.postRequest(
                                                    itemId: transaction.item._id,
                                                    message: message
                                                )
                                            case .accepted, .confirmed, .returned, .declined, .cancelled:
                                                try await transactionModel.updateRequest(transaction: transaction, newState: nextAction, message: message)
                                            }
                                            try await transactionModel.syncTransactions(modelContext: modelContext)
                                            dismiss()
                                        } catch {
                                            snackBar.show {
                                                SnackBarView.error(error)
                                            }
                                        }
                                    },
                                                actionOptions: [.showProgressView],
                                                label: {
                                        Text(nextAction.buttonLabel)
                                            .frame(maxWidth: .infinity)
                                    })
                                    .buttonStyle(.primary())
                                }
                            }
                            .frame(maxWidth: .infinity)
                        } else {
                            AsyncButton(action: {
                                do {
                                    try await transactionModel.postMessage(transactionId: transaction._id, message: message)

                                    try await transactionModel.syncTransactions(modelContext: modelContext)
                                } catch {
                                    snackBar.show { SnackBarView.error(error) }
                                }
                                dismiss()
                            },
                            actionOptions: [.showProgressView],
                            label: {
                                Text("action.send_message")
                                    .frame(maxWidth: .infinity)
                            })
                            .buttonStyle(.primary())
                        }
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
