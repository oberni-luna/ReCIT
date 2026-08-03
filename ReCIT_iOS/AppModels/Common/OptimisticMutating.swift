//
//  OptimisticMutating.swift
//  ReCIT_iOS
//
//  Standard optimistic-write runner for App → Server mutations.
//
//  Flow: mutate SwiftData locally and save immediately (the UI, being bound to
//  SwiftData, reacts at once), then run the web-service call in a background task
//  owned by the (app-scoped) model so it survives view/sheet dismissal. On
//  success an optional `reconcile` aligns the local store with server truth; on
//  failure the local change is reverted and the error is surfaced through the
//  shared `AppErrorReporter`.
//

import Foundation
import SwiftData

/// Identity scheme for locally-created placeholders that have not yet been
/// confirmed by the server. Reconcile/revert use `isOptimistic` to find them.
enum OptimisticID {
    static let prefix: String = "optimistic:"
    static func make() -> String { "\(prefix)\(UUID().uuidString)" }
    static func isOptimistic(_ id: String) -> Bool { id.hasPrefix(prefix) }
}

@MainActor
protocol OptimisticMutating: AnyObject {
    /// Shared channel used to surface a background failure to the UI.
    var errorReporter: AppErrorReporter? { get }
}

extension OptimisticMutating {
    /// - Parameters:
    ///   - apply: Mutates the local store (called synchronously, before the network).
    ///   - revert: Undoes `apply` if the request fails.
    ///   - request: The web-service call.
    ///   - reconcile: Optional post-success alignment with server truth.
    /// - Returns: The background task, so callers (and tests) can await completion.
    @discardableResult
    func optimistic(
        _ modelContext: ModelContext,
        apply: () -> Void,
        revert: @escaping () -> Void,
        request: @escaping () async throws -> Void,
        reconcile: @escaping () async throws -> Void = {}
    ) -> Task<Void, Never> {
        apply()
        try? modelContext.save()

        return Task { [weak self] in
            do {
                try await request()
                try await reconcile()
                try? modelContext.save()
            } catch {
                revert()
                try? modelContext.save()
                self?.errorReporter?.report(error)
            }
        }
    }
}
