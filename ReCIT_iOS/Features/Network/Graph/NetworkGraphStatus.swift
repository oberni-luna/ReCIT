//
//  NetworkGraphStatus.swift
//  ReCIT_iOS
//
//  What the pill at the bottom left of « Tout » says (PRD 0019, Q10, Q40, Q41):
//
//  - « 42 amis · 6 groupes » once my relations and my groups have both answered at least once;
//  - « Synchronisation… » while either is still on its way to a first answer;
//  - « Réessayer » when neither is on its way any more and one has failed without ever having
//    answered — a first launch offline. Tapping it runs the sync again.
//
//  Once both have answered, a later failure says nothing: the store is the last sync that worked
//  (Q41). Never « Tirez vers le bas »: nothing on « Tout » scrolls.
//

import Foundation

enum NetworkGraphStatus: Equatable {
    case counter(NetworkGraphCounter)
    case syncing
    case retry

    /// - Parameters:
    ///   - counter: What the graph counts.
    ///   - community: Where my relations' sync stands.
    ///   - groups: Where my groups' sync stands.
    init(
        counter: NetworkGraphCounter,
        community: SyncStatusStore.Phase,
        groups: SyncStatusStore.Phase
    ) {
        let phases: [SyncStatusStore.Phase] = [community, groups]
        if phases.allSatisfy({ $0 == .synced }) {
            self = .counter(counter)
        } else if phases.contains(.syncing) {
            self = .syncing
        } else if phases.contains(.failed) {
            self = .retry
        } else {
            self = .syncing
        }
    }

    /// Whether it is the counter, which the empty state does without (Q39).
    var isCounter: Bool {
        if case .counter = self {
            return true
        }
        return false
    }
}
