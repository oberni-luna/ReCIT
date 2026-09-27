//
//  GroupRequestLedger.swift
//  ReCIT_iOS
//
//  The groups I have asked to join, remembered on the device.
//
//  `GET /api/groups` answers with the groups where I am admin, member or invited — never those
//  where I am `requested`. Without a note of them, a request sent today would vanish from the
//  Groupes segment at the next launch, while it is still waiting on an admin. The ledger keeps
//  their ids, per account, and the sync reads each one back with `by-id` to see where it stands.
//
//  Ids only, and only what this device sent: a request made on the website is not known here
//  until it is answered.
//

import Foundation

struct GroupRequestLedger {
    private let defaults: UserDefaults
    private static let keyPrefix: String = "groups.requested."

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func ids(for userId: String) -> Set<String> {
        Set(defaults.stringArray(forKey: Self.keyPrefix + userId) ?? [])
    }

    func add(_ groupId: String, for userId: String) {
        write(ids(for: userId).union([groupId]), for: userId)
    }

    func remove(_ groupId: String, for userId: String) {
        write(ids(for: userId).subtracting([groupId]), for: userId)
    }

    private func write(_ ids: Set<String>, for userId: String) {
        defaults.set(ids.sorted(), forKey: Self.keyPrefix + userId)
    }
}
