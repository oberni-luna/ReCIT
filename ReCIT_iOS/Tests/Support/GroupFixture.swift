//
//  GroupFixture.swift
//  ReCIT_iOSTests
//
//  What the group suites build from: documents shaped like inventaire.io's, and a `GroupModel`
//  whose device memory — the requests ledger, who is signed in — is its own, or shared with
//  another to play a relaunch.
//

import Foundation
import SwiftData
@testable import ReCIT_iOS

/// The fixtures every group suite builds from: documents shaped like inventaire.io's, and a
/// model whose device memory — the ledger, who is signed in — is its own.
@MainActor
enum GroupFixture {
    static func groupJSON(
        id: String,
        name: String = "Club",
        open: Bool = false,
        admins: [String] = ["admin"],
        members: [String] = [],
        invited: [String] = [],
        requested: [String] = [],
        extra: String = ""
    ) -> String {
        func list(_ ids: [String]) -> String {
            "[" + ids.map { #"{"user":"\#($0)","invitor":null,"timestamp":1}"# }.joined(separator: ",") + "]"
        }
        return #"{"_id":"\#(id)","name":"\#(name)","open":\#(open),"searchable":true,\#(extra)"admins":\#(list(admins)),"members":\#(list(members)),"invited":\#(list(invited)),"declined":[],"requested":\#(list(requested))}"#
    }

    static func groupsJSON(_ groups: [String]) -> String {
        #"{"groups":["# + groups.joined(separator: ",") + "]}"
    }

    static func usersJSON(_ ids: [String]) -> String {
        #"{"users":{"# + ids.map { #""\#($0)":{"_id":"\#($0)","username":"\#($0)"}"# }.joined(separator: ",") + "}}"
    }

    /// A device of its own: the ledger and the signed-in reader live in these defaults.
    static func makeDefaults() -> UserDefaults {
        UserDefaults(suiteName: "group-tests-\(UUID().uuidString)") ?? .standard
    }

    /// - Parameter defaults: The device to share with another model — a relaunch. A fresh one
    ///   when `nil`.
    static func makeModel(
        _ mock: MockAPIService,
        reporter: AppErrorReporter? = nil,
        defaults: UserDefaults? = nil
    ) -> GroupModel {
        let defaults: UserDefaults = defaults ?? makeDefaults()
        return .init(
            apiService: mock,
            errorReporter: reporter,
            ledger: .init(defaults: defaults),
            defaults: defaults
        )
    }

    static func stored(_ context: ModelContext) throws -> [StoredGroup] {
        try context.fetch(FetchDescriptor<StoredGroup>())
    }

    /// My groups by section, as the Groupes segment reads them: from the store.
    static func myGroups(_ model: GroupModel, _ context: ModelContext) throws -> MyGroups {
        model.myGroups(from: try stored(context))
    }
}
