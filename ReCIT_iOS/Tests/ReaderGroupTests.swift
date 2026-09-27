//
//  ReaderGroupTests.swift
//  ReCIT_iOSTests
//
//  A group decoded from what inventaire.io actually sends, and every membership gesture played
//  against it. The transitions are the server's (`server/models/group.ts`): these tests are what
//  lets the app show a gesture's outcome before the server has answered.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@Suite("ReaderGroup")
struct ReaderGroupTests {

    /// A live `/api/groups/by-id` document, trimmed: an admin created it, nobody invited them.
    private static let liveJSON: String = #"""
    {"_id":"g1","_rev":"2-cf0c","type":"group","name":"Le Club de lecture",
     "admins":[{"user":"admin","invitor":null,"timestamp":1445431103207}],
     "members":[],"invited":[],"declined":[],"requested":[],
     "creator":"admin","created":1445431103207,"searchable":true,"slug":"le-club-de-lecture","open":false}
    """#

    private func group(
        open: Bool = false,
        admins: [String] = ["admin"],
        members: [String] = [],
        invited: [String] = [],
        declined: [String] = [],
        requested: [String] = []
    ) -> ReaderGroup {
        func list(_ ids: [String]) -> [GroupMembership] {
            ids.map { .init(user: $0, invitor: nil, timestamp: 0) }
        }
        return .init(
            id: "g1",
            name: "Club",
            slug: nil,
            description: "",
            pictureURL: nil,
            searchable: true,
            open: open,
            admins: list(admins),
            members: list(members),
            invited: list(invited),
            declined: list(declined),
            requested: list(requested)
        )
    }

    @Test("A live document decodes, a null invitor included")
    func decodesLiveDocument() throws {
        let dto: GroupDTO = try JSONDecoder().decode(GroupDTO.self, from: Data(Self.liveJSON.utf8))
        let group: ReaderGroup = .init(dto: dto, pictureURL: nil)

        #expect(group.name == "Le Club de lecture")
        #expect(group.admins.first?.invitor == nil)
        #expect(group.role(of: "admin") == .admin)
        #expect(group.open == false)
        #expect(group.memberCount == 1)
    }

    @Test("Each list gives its role, and a stranger has none")
    func roles() {
        let group: ReaderGroup = group(members: ["m"], invited: ["i"], declined: ["d"], requested: ["r"])

        #expect(group.role(of: "m") == .member)
        #expect(group.role(of: "i") == .invited)
        #expect(group.role(of: "d") == .declined)
        #expect(group.role(of: "r") == .requested)
        #expect(group.role(of: "stranger") == nil)
    }

    @Test("A request to a group on request waits; to an open group, it lets you in")
    func request() throws {
        #expect(try group().applying(.request, by: "me").role(of: "me") == .requested)
        #expect(try group(open: true).applying(.request, by: "me").role(of: "me") == .member)
    }

    @Test("A request from someone invited, or who declined, lets them in")
    func requestAfterInvitation() throws {
        #expect(try group(invited: ["me"]).applying(.request, by: "me").role(of: "me") == .member)
        #expect(try group(declined: ["me"]).applying(.request, by: "me").role(of: "me") == .member)
    }

    @Test("An invitation to someone who had asked accepts them")
    func inviteAcceptsARequest() throws {
        let group: ReaderGroup = try group(requested: ["r"]).applying(.invite, by: "admin", on: "r")
        #expect(group.role(of: "r") == .member)
    }

    @Test("An invitation remembers who sent it, and cannot reach someone who declined")
    func invite() throws {
        let invited: ReaderGroup = try group(members: ["m"]).applying(.invite, by: "m", on: "friend")
        #expect(invited.role(of: "friend") == .invited)
        #expect(invited.invitor(of: "friend") == "m")

        #expect(throws: GroupTransitionError.alreadyDeclined) {
            try group(declined: ["d"]).applying(.invite, by: "admin", on: "d")
        }
        #expect(throws: GroupTransitionError.alreadyInGroup) {
            try group(members: ["m"]).applying(.invite, by: "admin", on: "m")
        }
    }

    @Test("Answering an invitation moves me to members, or to declined")
    func answerInvitation() throws {
        #expect(try group(invited: ["me"]).applying(.accept, by: "me").role(of: "me") == .member)
        #expect(try group(invited: ["me"]).applying(.decline, by: "me").role(of: "me") == .declined)
    }

    @Test("An admin accepts or refuses a request, names an admin, removes a member")
    func adminGestures() throws {
        let base: ReaderGroup = group(members: ["m"], requested: ["a", "b"])
        #expect(try base.applying(.acceptRequest, by: "admin", on: "a").role(of: "a") == .member)
        #expect(try base.applying(.refuseRequest, by: "admin", on: "b").role(of: "b") == nil)
        #expect(try base.applying(.makeAdmin, by: "admin", on: "m").role(of: "m") == .admin)
        #expect(try base.applying(.kick, by: "admin", on: "m").role(of: "m") == nil)
    }

    @Test("An admin cannot be removed, only a member")
    func kickAnAdmin() {
        #expect(throws: GroupTransitionError.notInExpectedRole) {
            try group(admins: ["admin", "other"]).applying(.kick, by: "admin", on: "other")
        }
    }

    @Test("The only admin cannot leave while members remain")
    func lastAdmin() throws {
        #expect(group(members: ["m"]).canLeave("admin") == false)
        #expect(throws: GroupTransitionError.lastAdmin) {
            try group(members: ["m"]).applying(.leave, by: "admin")
        }
        #expect(try group().applying(.leave, by: "admin").role(of: "admin") == nil)
        #expect(try group(admins: ["admin", "b"], members: ["m"]).applying(.leave, by: "admin").role(of: "admin") == nil)
        #expect(try group(members: ["m"]).applying(.leave, by: "m").role(of: "m") == nil)
    }

    @Test("Cancelling a request takes me out")
    func cancelRequest() throws {
        #expect(try group(requested: ["me"]).applying(.cancelRequest, by: "me").role(of: "me") == nil)
    }

    @Test("A setting is written onto the group, and travels as a string or a boolean")
    func settings() throws {
        let renamed: ReaderGroup = GroupSetting.name("Polars").applied(to: group())
        #expect(renamed.name == "Polars")
        #expect(GroupSetting.open(true).applied(to: group()).open)

        let payload: GroupSettingPayload = .init(group: "g1", attribute: "open", value: GroupSetting.open(true).value)
        let json: String = String(decoding: try JSONEncoder().encode(payload), as: UTF8.self)
        #expect(json.contains(#""value":true"#))
    }
}
