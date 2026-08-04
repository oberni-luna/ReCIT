//
//  TransactionTransition.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 04/08/2026.
//

import Foundation

/// A single edge of the transaction state machine: who can trigger which event,
/// from which state, to which resulting state, and whether a message is required.
struct TransactionTransition: Equatable, Hashable {
    let event: TransactionEvent
    /// The state the transaction must be in for this transition to apply.
    /// `nil` means the transition *creates* the transaction (the initial request).
    let from: UserTransaction.TransactionState?
    let to: UserTransaction.TransactionState
    let actor: TransactionRole
    let requiresMessage: Bool
}
