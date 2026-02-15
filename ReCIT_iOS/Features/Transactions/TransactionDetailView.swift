//
//  TransactionDetailView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 07/02/2026.
//
import SwiftData
import SwiftUI

struct TransactionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var userModel: UserModel
    
    let transaction: UserTransaction

    @State private var showTransactionForm: Bool = false

    var body: some View {
        List {
            Section {
                TransactionCellView(transaction: transaction)
            }

            if let user = userModel.myUser {
                if transaction.messages.count >= 1 {
                    Section("Messages") {
                        ForEach(transaction.getUIMessages(for: user).sorted { $0.timestamp < $1.timestamp }) { message in
                            messageView(message: message)
                        }
                    }
                }

                Section {} footer: {
                    Button {
                        showTransactionForm = true
                    } label: {
                        if let _ = transaction.nextAvailableState(for: user) {
                            Text("Répondre")
                        } else {
                            Text("Envoyer un message")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .sheet(isPresented: $showTransactionForm) {
            TransactionFormView(transaction: transaction)
        }
    }

    @ViewBuilder
    func messageView(message: UserTransaction.TransactionUIMessage) -> some View {
        switch message.direction {
        case .action(let action):
            HStack(alignment: .top, spacing: .small) {
                Image(systemName: action.systemImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24)
                    .padding(.horizontal, .xSmall)
                VStack(alignment: .leading, spacing: .small) {
                    Text(.init(message.text))
                    Text(message.timestamp.formatted(date: .abbreviated, time: .standard))
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
            }
        default:
            HStack(alignment: .top, spacing: .small) {
                CellThumbnail(imageUrl: message.user.avatarURLValue, cornerRadius: .full, size: 32)
                VStack(alignment: .leading, spacing: .xSmall) {
                    Text(message.user.username)
                        .bold()

                    Text(.init(message.text))

                    Text(message.timestamp.formatted(date: .abbreviated, time: .standard))
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
            }
        }
    }


}

extension UserTransaction {
    enum MessageDirection {
        case incoming
        case outgoing
        case action(action: TransactionState)
    }

    struct TransactionUIMessage: Identifiable {
        let id: String
        let direction: MessageDirection
        let user: User
        let text: String
        let timestamp: Date
    }

    func getUIMessages(for user: User) -> [TransactionUIMessage] {
        var amIRequester: Bool {
            self.requester._id == user._id
        }

        let messages: [TransactionUIMessage] = self.messages.map { message in
            if message.user._id == user._id {
                TransactionUIMessage(
                    id: message._id, direction: .outgoing, user: user, text: message.message, timestamp: message.created)
            } else {
                TransactionUIMessage(
                    id: message._id, direction: .incoming, user: otherUser(for: user), text: message.message, timestamp: message.created)
            }
        }
        let actions: [TransactionUIMessage] = getActionUIMessages(amIRequester: amIRequester)

        return messages + actions
    }

    func otherUser(for user: User) -> User {
        if self.owner._id == user._id {
            return self.requester
        } else {
            return self.owner
        }
    }

    func getActionUIMessages(amIRequester: Bool) -> [TransactionUIMessage] {
        self.actions.map { action in
            TransactionUIMessage(id: action.action.rawValue, direction: .action(action: action.action), user: getActionMessageUser(action: action), text: getActionMessageContent(action: action, amIRequester: amIRequester), timestamp: action.timestamp)
        }
    }

    func getActionMessageContent(action: TransactionAction, amIRequester: Bool) -> String {
        return if amIRequester {
            switch action.action {
            case .requested:
                "Vous avez fait une demande d'emprunt à **\(self.owner.username)**"
            case .accepted:
                "**\(self.owner.username)** a accepté la demande"
            case .confirmed:
                "Vous avez confirmé la réception"
            case .returned:
                "Vous avez retourné le livre"
            case .declined:
                "**\(self.owner.username)** a refusé cette demande"
            }
        } else {
            switch action.action {
            case .requested:
                "**\(self.requester.username)** vous a fait une demande"
            case .accepted:
                "Vous avez accepté la demande"
            case .confirmed:
                "**\(self.owner.username)** a confirmé la réception"
            case .returned:
                "Vous avez récupéré le livre"
            case .declined:
                "Vous avez refusé cette demande"
            }
        }
    }

    func getActionMessageUser(action: TransactionAction) -> User {
        switch action.action {
        case .requested:
            self.requester
        case .accepted:
            self.owner
        case .confirmed:
            self.requester
        case .returned:
            self.owner
        case .declined:
            self.owner
        }
    }
}

