//
//  TransactionsWithUser.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 06/11/2026.
//

/// The Échanges between me and one reader, as the Échanges tab of their profile lists them:
/// those still going on, then those that are over, each the latest action first. Either side of
/// the copy counts — a book of theirs I asked for, or one of mine they did.
struct TransactionsWithUser {
    let current: [UserTransaction]
    let finished: [UserTransaction]

    var count: Int {
        current.count + finished.count
    }

    var isEmpty: Bool {
        current.isEmpty && finished.isEmpty
    }

    init(_ transactions: [UserTransaction], userId: String) {
        let shared: [UserTransaction] = transactions
            .filter { $0.owner._id == userId || $0.requester._id == userId }
            .sorted { $0.lastActionDate > $1.lastActionDate }
        current = shared.filter(\.isCurrent)
        finished = shared.filter { $0.isCurrent == false }
    }

    /// Whether one of them waits to be read on my side.
    func hasUnread(by myId: String?) -> Bool {
        (current + finished).contains { $0.isRead(by: myId) == false }
    }
}
