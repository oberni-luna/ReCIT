//
//  ShelfEmptyStateErrandTests.swift
//  ReCIT_iOSTests
//
//  What the empty shelf offers, per state. Pure and network-free.
//
//  The point being pinned is the one the card exists for: an empty inventory is offered the
//  two ways of filling it and nothing else — no sorting, since there is nothing to sort — and
//  an inventory with books is offered the one way of arranging them. See docs/features/0021.
//

import Testing
@testable import ReCIT_iOS

@Suite struct ShelfEmptyStateErrandTests {

    @Test func anEmptyInventoryAsksToBeFilled() {
        let errand: ShelfEmptyStateErrand = .init(ownsBooks: false)
        #expect(errand == .scan)
        #expect(errand.actions == [.scan, .search])
    }

    @Test func booksOnNoShelfAskToBeArranged() {
        let errand: ShelfEmptyStateErrand = .init(ownsBooks: true)
        #expect(errand == .sort)
        #expect(errand.actions == [.sort])
    }

    @Test func everyActionHasItsOwnIdentifier() {
        let actions: [ShelfEmptyStateAction] = [.scan, .search, .sort]
        let identifiers: Set<String> = .init(actions.map(\.accessibilityIdentifier))
        #expect(identifiers.count == actions.count)
    }
}
