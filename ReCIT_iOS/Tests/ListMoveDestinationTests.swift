//
//  ListMoveDestinationTests.swift
//  ReCIT_iOSTests
//

import Testing
@testable import ReCIT_iOS

@Suite("ListMoveDestination")
struct ListMoveDestinationTests {

    @Test("offers the other lists of the same type, by name, greying those that hold the element")
    func destinations() {
        let candidates: [ListMoveDestination.Candidate] = [
            .init(id: "current", name: "À lire", type: .work, uris: ["wd:Q1"]),
            .init(id: "zola", name: "zola", type: .work, uris: []),
            .init(id: "authors", name: "Autrices", type: .author, uris: []),
            .init(id: "read", name: "Lus", type: .work, uris: ["wd:Q1"]),
            .init(id: "gifts", name: "Cadeaux", type: .work, uris: ["wd:Q2"]),
        ]

        let destinations: [ListMoveDestination] = ListMoveDestination.destinations(
            for: "wd:Q1",
            from: "current",
            type: .work,
            among: candidates
        )

        #expect(destinations.map(\.id) == ["gifts", "read", "zola"])
        #expect(destinations.map(\.alreadyHolds) == [false, true, false])
    }

    @Test("offers nothing when the list is the only one of its type")
    func noDestination() {
        let candidates: [ListMoveDestination.Candidate] = [
            .init(id: "current", name: "À lire", type: .work, uris: ["wd:Q1"]),
            .init(id: "authors", name: "Autrices", type: .author, uris: []),
        ]

        #expect(ListMoveDestination.destinations(for: "wd:Q1", from: "current", type: .work, among: candidates).isEmpty)
    }
}
