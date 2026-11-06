//
//  TransactionSections.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 06/11/2026.
//

/// Échanges as « Toutes les transactions » and a friend's Échanges tab list them: those still
/// going on, then those that are over, each the latest action first. Given a reader, only the
/// Échanges with them, whichever side of the copy they are on.
struct TransactionSections {
    let current: [UserTransaction]
    let finished: [UserTransaction]

    var count: Int {
        current.count + finished.count
    }

    var isEmpty: Bool {
        current.isEmpty && finished.isEmpty
    }

    init(_ transactions: [UserTransaction], with userId: String? = nil) {
        let kept: [UserTransaction] = transactions
            .filter { userId == nil || $0.owner._id == userId || $0.requester._id == userId }
            .sorted { $0.lastActionDate > $1.lastActionDate }
        current = kept.filter(\.isCurrent)
        finished = kept.filter { $0.isCurrent == false }
    }

    /// Whether one of them waits to be read on my side.
    func hasUnread(by myId: String?) -> Bool {
        (current + finished).contains { $0.isRead(by: myId) == false }
    }
}
