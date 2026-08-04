//
//  TransactionDetailView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 07/02/2026.
//
import LBSnackBar
import SwiftData
import SwiftUI

struct TransactionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.snackBar) private var snackBar
    @Environment(UserModel.self) private var userModel
    @Environment(TransactionModel.self) private var transactionModel

    /// The live transaction, sourced from SwiftData by id so the view always
    /// renders the current persisted instance and reacts to background changes.
    @Query private var liveTransactions: [UserTransaction]
    private let fallbackTransaction: UserTransaction
    @Binding var path: NavigationPath

    /// Presents the free-message form. State changes no longer use a form — they
    /// run straight from the action bar.
    @State private var showMessageForm: Bool = false

    init(transaction: UserTransaction, path: Binding<NavigationPath>) {
        self.fallbackTransaction = transaction
        self._path = path
        let id: String = transaction._id
        _liveTransactions = Query(filter: #Predicate<UserTransaction> { $0._id == id })
    }

    private var transaction: UserTransaction {
        liveTransactions.first ?? fallbackTransaction
    }

    var body: some View {
        List {
            Section {
                Button {
                    path.append(NavigationDestination.item(item: transaction.item))
                } label: {
                    NavigationLink(value: UUID()) {
                        TransactionCellView(transaction: transaction)
                    }
                }
                .buttonStyle(.plain)
            }

            if let user = userModel.myUser {
                if transaction.messages.count >= 1 {
                    Section("transaction.messages.header") {
                        ForEach(transaction.getUIMessages(for: user).sorted { $0.timestamp < $1.timestamp }) { message in
                            messageView(message: message)
                        }
                    }
                }

                if !transaction.state.isFinished {
                    Section {} footer: {
                        TransactionActionsBar(
                            transaction: transaction,
                            user: user,
                            onEvent: { transition in
                                await perform(transition: transition, author: user)
                            },
                            onMessage: {
                                showMessageForm = true
                            }
                        )
                    }
                }
            }
        }
        .applyListBackground()
        .sheet(isPresented: $showMessageForm) {
            TransactionFormView(transaction: transaction, transition: nil)
        }
    }

    /// Runs a state-machine transition through the model, surfacing any immediate
    /// failure via the snackbar. Background (optimistic) failures surface on their
    /// own through the shared error reporter.
    private func perform(transition: TransactionTransition, author: User) async {
        do {
            try await transactionModel.perform(
                event: transition.event,
                on: transaction,
                message: nil,
                author: author,
                modelContext: modelContext
            )
        } catch {
            snackBar.show { SnackBarView.error(error) }
        }
    }

    @ViewBuilder
    func messageView(message: UserTransaction.TransactionUIMessage) -> some View {
        switch message.direction {
        case .action(let action):
            HStack(alignment: .top, spacing: .sMedium) {
                Image(systemName: action.systemImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                    .foregroundStyle(.foregroundTinted)
                    .padding(.all, .small)
                    .background(.backgroundTinted)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: .small) {
                    Text(.init(message.text))
                        .foregroundStyle(.foregroundDefault)
                        .textStyle(.content300)

                    Text(message.timestamp.formatted(date: .abbreviated, time: .standard))
                        .foregroundStyle(.foregroundSecondary)
                        .textStyle(.content300)
                }
            }
        default:
            HStack(alignment: .top, spacing: .sMedium) {
                CellThumbnail(imageUrl: message.user.avatarURLValue, cornerRadius: .full, size: .small)
                VStack(alignment: .leading, spacing: .xSmall) {
                    Text(message.user.username)
                        .textStyle(.content400Bold)
                        .foregroundStyle(.foregroundDefault)

                    Text(.init(message.text))
                        .textStyle(.content300)
                        .foregroundStyle(.foregroundDefault)

                    Text(message.timestamp.formatted(date: .abbreviated, time: .standard))
                        .foregroundStyle(.foregroundSecondary)
                        .textStyle(.content300)
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
                String(localized: "transaction.action.requester.requested \(self.owner.username)")
            case .accepted:
                String(localized: "transaction.action.requester.accepted \(self.owner.username)")
            case .confirmed:
                String(localized: "transaction.action.requester.confirmed")
            case .returned:
                String(localized: "transaction.action.requester.returned")
            case .declined:
                String(localized: "transaction.action.requester.declined \(self.owner.username)")
            case .cancelled:
                String(localized: "transaction.action.cancelled")
            }
        } else {
            switch action.action {
            case .requested:
                String(localized: "transaction.action.owner.requested \(self.requester.username)")
            case .accepted:
                String(localized: "transaction.action.owner.accepted")
            case .confirmed:
                String(localized: "transaction.action.owner.confirmed \(self.owner.username)")
            case .returned:
                String(localized: "transaction.action.owner.returned")
            case .declined:
                String(localized: "transaction.action.owner.declined")
            case .cancelled:
                String(localized: "transaction.action.cancelled")
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
        case .cancelled:
            self.requester
        }
    }
}

