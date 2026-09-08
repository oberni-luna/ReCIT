//
//  MembershipMenuEntryTests.swift
//  ReCIT_iOSTests
//
//  The membership menus offer every container the user owns, each line flagged with which way
//  it goes. What can be got wrong is the flagging and what happens to a membership that points
//  somewhere the user no longer owns — which is what these cover.
//

import Testing
@testable import ReCIT_iOS

@Suite struct MembershipMenuEntryTests {

    private let candidates: [(id: String, name: String)] = [
        (id: "s1", name: "Classiques français"),
        (id: "s2", name: "Romans policiers"),
        (id: "s3", name: "Science-fiction"),
    ]

    @Test func flagsTheContainersTheEntityIsIn() {
        let entries: [MembershipMenuEntry] = MembershipMenuEntry.entries(
            candidates: candidates,
            memberIDs: ["s2"]
        )

        #expect(entries.map(\.isMember) == [false, true, false])
    }

    @Test func keepsTheCandidateOrderAndNames() {
        let entries: [MembershipMenuEntry] = MembershipMenuEntry.entries(
            candidates: candidates,
            memberIDs: []
        )

        #expect(entries.map(\.id) == ["s1", "s2", "s3"])
        #expect(entries.map(\.name) == ["Classiques français", "Romans policiers", "Science-fiction"])
    }

    /// A membership left over from a container the user no longer owns has no name to show, so
    /// it must not add a line of its own.
    @Test func ignoresAMembershipInAContainerThatIsGone() {
        let entries: [MembershipMenuEntry] = MembershipMenuEntry.entries(
            candidates: [(id: "s1", name: "Classiques français")],
            memberIDs: ["gone"]
        )

        #expect(entries.count == 1)
        #expect(entries[0].isMember == false)
    }

    @Test func offersNothingWithoutContainers() {
        #expect(MembershipMenuEntry.entries(candidates: [], memberIDs: ["s1"]).isEmpty)
    }
}
