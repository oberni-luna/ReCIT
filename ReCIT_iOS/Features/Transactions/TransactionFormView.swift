//
//  TransactionFormView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 30/11/2025.
//

import SwiftUI

struct TransactionFormView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var userModel: UserModel
    @EnvironmentObject var transactionModel: TransactionModel

    @Bindable var transaction: UserTransaction
    @State var message: String = ""

    var body: some View {
        NavigationStack {
            Form {
                if transaction._id.isEmpty {
                    Section {
                        Picker("Transaction", selection: $transaction.type) {
                            ForEach(TransactionType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: .xSmall) {
                        Text("Your message")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .bold()
                        TextEditor(text: $message)
                            .frame(minHeight: 48)
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
                                            case .accepted, .confirmed, .returned, .declined:
                                                try await transactionModel.updateRequest(transaction: transaction, newState: nextAction, message: message)
                                            }
                                            try await transactionModel.syncTransactions(modelContext: modelContext)
                                            dismiss()
                                        } catch {
                                            print(error)
                                        }
                                    },
                                                actionOptions: [.showProgressView],
                                                label: {
                                        Text(nextAction.buttonLabel)
                                            .frame(maxWidth: .infinity)
                                    })
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.large)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        } else {
                            AsyncButton(action: {
                                do {
                                    try await transactionModel.postMessage(transactionId: transaction._id, message: message)

                                    try await transactionModel.syncTransactions(modelContext: modelContext)
                                } catch {
                                    print(error)
                                }
                                dismiss()
                            },
                            actionOptions: [.showProgressView],
                            label: {
                                Text("Envoyer un message")
                                    .frame(maxWidth: .infinity)
                            })
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                        }
                    }
                    .listRowSeparator(.visible)
                    .listSectionSeparator(.hidden)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer", systemImage: "xmark") {
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
