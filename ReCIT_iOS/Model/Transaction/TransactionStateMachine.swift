//
//  TransactionStateMachine.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 04/08/2026.
//

import Foundation

/// Single source of truth for the transaction lifecycle.
///
/// Every rule about *who* can do *what*, *when*, and whether a message is
/// required lives in `transitions`. Adding or changing a rule is a one-line edit
/// to the table, and the whole machine is pure (no SwiftData, no network) so it
/// can be unit-tested in isolation.
enum TransactionStateMachine {
    typealias State = UserTransaction.TransactionState

    /// The transition that creates a transaction: the requester's initial request.
    /// A message is mandatory here (and only here).
    static let requestTransition: TransactionTransition = .init(
        event: .request,
        from: nil,
        to: .requested,
        actor: .requester,
        requiresMessage: true
    )

    static let transitions: [TransactionTransition] = [
        requestTransition,
        .init(event: .accept,  from: .requested, to: .accepted,  actor: .owner,     requiresMessage: false),
        .init(event: .reject,  from: .requested, to: .declined,  actor: .owner,     requiresMessage: false),
        .init(event: .cancel,  from: .requested, to: .cancelled, actor: .requester, requiresMessage: false),
        .init(event: .confirm, from: .accepted,  to: .confirmed, actor: .requester, requiresMessage: false),
        .init(event: .cancel,  from: .accepted,  to: .cancelled, actor: .requester, requiresMessage: false),
        .init(event: .cancel,  from: .accepted,  to: .cancelled, actor: .owner,     requiresMessage: false),
        .init(event: .close,   from: .confirmed, to: .returned,  actor: .owner,     requiresMessage: false)
    ]

    /// The transitions a given role can trigger from a given state, in table order.
    static func available(from state: State, role: TransactionRole) -> [TransactionTransition] {
        transitions.filter { $0.from == state && $0.actor == role }
    }
}
