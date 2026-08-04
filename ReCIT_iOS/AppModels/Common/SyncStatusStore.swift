//
//  SyncStatusStore.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 03/08/2026.
//

import Foundation
import Observation

/// Tracks, per data domain, whether the app has ever completed a first successful
/// sync with the server.
///
/// The reactive UI reads SwiftData directly, so an empty `@Query` result is
/// ambiguous: it can mean "the server really has nothing" or "we haven't synced
/// yet". This store removes the ambiguity. A view shows a syncing placeholder
/// while `hasCompletedFirstSync(_:)` is `false`, and switches to the (possibly
/// empty) database content once the first sync succeeds.
///
/// The "first sync completed" marker is persisted across launches: once a domain
/// has synced once, later launches show cached content immediately and refresh in
/// the background, never the placeholder again.
@MainActor
@Observable
final class SyncStatusStore {

    /// A synchronizable data domain, one per top-level reactive screen.
    ///
    /// Inventory is intentionally absent: its sync state is per-user and tracked
    /// on `User.lastInventorySync` (nil == never synced), since a friend's
    /// inventory can be synced independently of our own.
    enum Domain: String, CaseIterable, Sendable {
        case lists
        case transactions
        case community
    }

    /// Current sync state of a domain within this launch.
    enum Phase: Sendable {
        /// No sync started yet this launch and none ever completed.
        case pending
        /// A sync is in flight and no prior sync has ever completed.
        case syncing
        /// At least one sync has completed successfully (ever).
        case synced
        /// The latest sync failed and none has ever completed.
        case failed
    }

    /// Domains whose first sync has ever completed. Mirrored to `UserDefaults`
    /// and kept as an observed property so views react when it changes.
    private var completedDomains: Set<Domain>

    /// In-launch phase for domains that have not yet completed a first sync.
    private var activePhases: [Domain: Phase] = [:]

    private let defaults: UserDefaults
    private static let defaultsKey: String = "SyncStatusStore.completedDomains"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let stored: [String] = defaults.stringArray(forKey: Self.defaultsKey) ?? []
        self.completedDomains = Set(stored.compactMap(Domain.init(rawValue:)))
    }

    // MARK: - Queries

    /// `true` once `domain` has completed a first successful sync (ever). Views use
    /// this to switch from the syncing placeholder to database content.
    func hasCompletedFirstSync(_ domain: Domain) -> Bool {
        completedDomains.contains(domain)
    }

    /// The current phase of `domain`. Returns `.synced` as soon as a first sync has
    /// ever completed, regardless of any later background refresh.
    func phase(_ domain: Domain) -> Phase {
        if completedDomains.contains(domain) {
            return .synced
        }
        return activePhases[domain] ?? .pending
    }

    /// Whether the syncing placeholder should replace the content of `domain`'s
    /// screen. `true` until the very first sync completes.
    func shouldShowPlaceholder(_ domain: Domain) -> Bool {
        !hasCompletedFirstSync(domain)
    }

    // MARK: - Mutations

    /// Marks a sync as started. No-op once the domain has completed a first sync,
    /// so background refreshes never revert a screen to the placeholder.
    func markStarted(_ domain: Domain) {
        guard !completedDomains.contains(domain) else { return }
        activePhases[domain] = .syncing
    }

    /// Records a successful sync. Persisted so later launches skip the placeholder.
    func markCompleted(_ domain: Domain) {
        activePhases[domain] = nil
        guard !completedDomains.contains(domain) else { return }
        completedDomains.insert(domain)
        persist()
    }

    /// Records a failed sync. Leaves the placeholder in place (with no prior
    /// success) so the next refresh retries.
    func markFailed(_ domain: Domain) {
        guard !completedDomains.contains(domain) else { return }
        activePhases[domain] = .failed
    }

    /// Clears all persisted first-sync markers, e.g. on logout / account switch.
    func reset() {
        activePhases.removeAll()
        completedDomains.removeAll()
        persist()
    }

    // MARK: - Private

    private func persist() {
        defaults.set(completedDomains.map(\.rawValue), forKey: Self.defaultsKey)
    }
}
