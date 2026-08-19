//
//  ShelfMenuOptionsTests.swift
//  ReCIT_iOSTests
//
//  Unit tests for the étagère entries of the book menu. Pure and network-free, like the
//  shelf layout suite — no SwiftUI, no SwiftData, no production server.
//
//  What is worth pinning here is the filtering and the boundaries: the menu must never
//  offer an action that would do nothing, and the 0 / 1 / many switch happens on the
//  *filtered* list, which is exactly the kind of off-by-one that looks right in a
//  screenshot. See PRD 0004.
//

import Testing
@testable import ReCIT_iOS

@Suite struct ShelfMenuOptionsTests {

    private let classiques: ShelfMenuOptions.Entry = .init(id: "s1", name: "Classiques français")
    private let policiers: ShelfMenuOptions.Entry = .init(id: "s2", name: "Romans policiers")
    private let sf: ShelfMenuOptions.Entry = .init(id: "s3", name: "Science-fiction")

    private func options(
        user: [ShelfMenuOptions.Entry],
        item: [ShelfMenuOptions.Entry]
    ) -> ShelfMenuOptions {
        .init(userShelves: user, itemShelves: item)
    }

    // MARK: - Add list: what it contains

    @Test func addListExcludesShelvesTheItemIsAlreadyOn() {
        let result: ShelfMenuOptions = options(user: [classiques, policiers, sf], item: [policiers])
        #expect(result.add.entries == [classiques, sf])
    }

    @Test func addListKeepsTheUserShelfOrder() {
        let result: ShelfMenuOptions = options(user: [sf, classiques, policiers], item: [])
        #expect(result.add.entries.map(\.id) == ["s3", "s1", "s2"])
    }

    @Test func addListIgnoresAMembershipTheUserNoLongerOwns() {
        let stale: ShelfMenuOptions.Entry = .init(id: "gone", name: "Étagère supprimée")
        let result: ShelfMenuOptions = options(user: [classiques], item: [stale])
        #expect(result.add.entries == [classiques])
        #expect(result.remove.entries.isEmpty)
    }

    // MARK: - Add list: 0 / 1 / many

    @Test func noShelvesAtAllYieldsNoAddEntry() {
        let result: ShelfMenuOptions = options(user: [], item: [])
        #expect(result.add == .empty)
    }

    @Test func oneEligibleShelfIsNamedOutright() {
        let result: ShelfMenuOptions = options(user: [classiques, policiers], item: [policiers])
        #expect(result.add == .single(classiques))
    }

    @Test func twoEligibleShelvesFanOutIntoASubmenu() {
        let result: ShelfMenuOptions = options(user: [classiques, policiers, sf], item: [sf])
        #expect(result.add == .submenu([classiques, policiers]))
    }

    /// The 0 / 1 / many switch happens *after* filtering: three shelves, two of them
    /// already used, is a single entry and not a submenu.
    @Test func theShapeFollowsTheFilteredListNotTheRawOne() {
        let result: ShelfMenuOptions = options(user: [classiques, policiers, sf], item: [classiques, sf])
        #expect(result.add == .single(policiers))
    }

    @Test func aBookOnEveryShelfYieldsNoAddEntry() {
        let result: ShelfMenuOptions = options(user: [classiques, policiers, sf], item: [classiques, policiers, sf])
        #expect(result.add == .empty)
    }

    // MARK: - Remove list

    @Test func removeListIsExactlyTheItemsShelves() {
        let result: ShelfMenuOptions = options(user: [classiques, policiers, sf], item: [classiques, sf])
        #expect(result.remove.entries == [classiques, sf])
    }

    @Test func aBookOnNoShelfYieldsNoRemoveEntry() {
        let result: ShelfMenuOptions = options(user: [classiques, policiers, sf], item: [])
        #expect(result.remove == .empty)
    }

    @Test func oneMembershipIsNamedOutright() {
        let result: ShelfMenuOptions = options(user: [classiques, policiers, sf], item: [policiers])
        #expect(result.remove == .single(policiers))
    }

    @Test func severalMembershipsFanOutIntoASubmenu() {
        let result: ShelfMenuOptions = options(user: [classiques, policiers, sf], item: [policiers, sf])
        #expect(result.remove == .submenu([policiers, sf]))
    }

    // MARK: - The two sides together

    @Test func noShelvesYieldsNeitherEntry() {
        let result: ShelfMenuOptions = options(user: [], item: [])
        #expect(result.add == .empty)
        #expect(result.remove == .empty)
    }

    @Test func theTwoListsNeverOverlapAndCoverEveryShelf() {
        let user: [ShelfMenuOptions.Entry] = [classiques, policiers, sf]
        for membership in [[], [classiques], [classiques, sf], user] {
            let result: ShelfMenuOptions = options(user: user, item: membership)
            let addIDs: Set<String> = .init(result.add.entries.map(\.id))
            let removeIDs: Set<String> = .init(result.remove.entries.map(\.id))
            #expect(addIDs.isDisjoint(with: removeIDs))
            #expect(addIDs.union(removeIDs) == Set(user.map(\.id)))
        }
    }
}
