//
//  AppErrorReporter.swift
//  ReCIT_iOS
//
//  Single reactive channel for surfacing background failures (optimistic
//  mutations, background syncs) to the UI. Injected app-wide and observed once
//  near the root, which shows a SnackBar — so features never each wire their own
//  error plumbing.
//

import Foundation

@MainActor
@Observable
final class AppErrorReporter {
    private(set) var lastFailure: SyncFailure?

    func report(_ error: Error) {
        lastFailure = .init(error: error)
    }
}
