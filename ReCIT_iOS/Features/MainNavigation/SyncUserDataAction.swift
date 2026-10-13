//
//  SyncUserDataAction.swift
//  ReCIT_iOS
//
//  Runs the signed-in reader's sync again, as pull-to-refresh does — for a screen with nothing to
//  pull: the « Réessayer » of « Tout » after a first launch whose sync failed (PRD 0019, Q41).
//  `RootView` sets it in the environment, next to its `.refreshable`; anywhere else it does
//  nothing.
//
//  A value rather than a bare closure, so the environment can compare it: there is one sync, so
//  two actions are always the same one, and setting it again never invalidates a view.
//

import Foundation

struct SyncUserDataAction: Equatable {
    private let action: @MainActor () -> Void

    init(_ action: @escaping @MainActor () -> Void) {
        self.action = action
    }

    func callAsFunction() {
        action()
    }

    static func == (lhs: SyncUserDataAction, rhs: SyncUserDataAction) -> Bool {
        true
    }
}
