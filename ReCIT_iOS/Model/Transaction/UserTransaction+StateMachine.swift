//
//  UserTransaction+StateMachine.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 04/08/2026.
//

import Foundation

extension UserTransaction {

    /// Which side of this transaction the given user is on.
    func role(for user: User) -> TransactionRole {
        requester._id == user._id ? .requester : .owner
    }

    /// Every transition the given user can currently trigger, in table order.
    func availableTransitions(for user: User) -> [TransactionTransition] {
        TransactionStateMachine.available(from: state, role: role(for: user))
    }

    /// The primary "forward" transition to surface as the default action, if any
    /// (accept / confirm / close). At most one exists for a given state and role.
    func defaultTransition(for user: User) -> TransactionTransition? {
        availableTransitions(for: user).first { $0.event.isDefault }
    }

    /// The remaining transitions (everything but the default), for the overflow menu.
    func secondaryTransitions(for user: User) -> [TransactionTransition] {
        availableTransitions(for: user).filter { !$0.event.isDefault }
    }
}
