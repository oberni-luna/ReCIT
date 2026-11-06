//
//  TransactionsWithUserTests.swift
//  ReCIT_iOSTests
//
//  Created by Olivier Berni on 06/11/2026.
//

import Foundation
import SwiftData
import Testing
@testable import ReCIT_iOS

@MainActor
@Suite(.serialized)
struct TransactionsWithUserTests {
    private let context: ModelContext
    private let myself: User
    private let camille: User
    private let sacha: User

    init() throws {
        context = try TestStore.makeContext()
        myself = Fixture.user(id: "myself", username: "myself")
        camille = Fixture.user(id: "camille", username: "Camille", relation: .friend)
        sacha = Fixture.user(id: "sacha", username: "Sacha", relation: .friend)
        for user in [myself, camille, sacha] {
            context.insert(user)
        }
    }

    @Test
    func `keeps the transactions with that reader, whichever of us owns the copy`() {
        let theirs: UserTransaction = transaction("theirs", owner: camille, requester: myself)
        let mine: UserTransaction = transaction("mine", owner: myself, requester: camille)
        let other: UserTransaction = transaction("other", owner: sacha, requester: myself)

        let shared: TransactionsWithUser = .init([theirs, mine, other], userId: camille._id)

        #expect(shared.count == 2)
        #expect(Set((shared.current + shared.finished).map(\._id)) == ["theirs", "mine"])
    }

    @Test
    func `puts ongoing transactions apart from finished ones`() {
        let ongoing: [UserTransaction] = [
            transaction("requested", state: .requested),
            transaction("accepted", state: .accepted),
            transaction("confirmed", state: .confirmed)
        ]
        let over: [UserTransaction] = [
            transaction("returned", state: .returned),
            transaction("declined", state: .declined),
            transaction("cancelled", state: .cancelled)
        ]

        let shared: TransactionsWithUser = .init(ongoing + over, userId: camille._id)

        #expect(Set(shared.current.map(\._id)) == ["requested", "accepted", "confirmed"])
        #expect(Set(shared.finished.map(\._id)) == ["returned", "declined", "cancelled"])
    }

    @Test
    func `sorts each section by its last action, the newest first`() {
        let transactions: [UserTransaction] = [
            transaction("old", state: .accepted, lastAction: 10),
            transaction("new", state: .requested, lastAction: 30),
            transaction("middle", state: .confirmed, lastAction: 20),
            transaction("long ago", state: .returned, lastAction: 5),
            transaction("lately", state: .cancelled, lastAction: 40)
        ]

        let shared: TransactionsWithUser = .init(transactions, userId: camille._id)

        #expect(shared.current.map(\._id) == ["new", "middle", "old"])
        #expect(shared.finished.map(\._id) == ["lately", "long ago"])
    }

    @Test
    func `is empty with a reader I never had a transaction with`() {
        let other: UserTransaction = transaction("other", owner: sacha, requester: myself)

        let shared: TransactionsWithUser = .init([other], userId: camille._id)

        #expect(shared.isEmpty)
    }

    @Test
    func `flags an unread transaction by the rule of its row, on my side only`() {
        let unreadByMe: UserTransaction = transaction(
            "asked",
            owner: camille,
            requester: myself,
            readStatus: .init(owner: false, requester: true)
        )
        let unreadByThem: UserTransaction = transaction(
            "lent",
            owner: myself,
            requester: camille,
            readStatus: .init(owner: false, requester: true)
        )

        #expect(unreadByMe.isRead(by: myself._id) == false)
        #expect(TransactionsWithUser([unreadByMe], userId: camille._id).hasUnread(by: myself._id))
        #expect(unreadByThem.isRead(by: myself._id))
        #expect(TransactionsWithUser([unreadByThem], userId: camille._id).hasUnread(by: myself._id) == false)
    }

    private func transaction(
        _ id: String,
        owner: User? = nil,
        requester: User? = nil,
        state: UserTransaction.TransactionState = .requested,
        lastAction: TimeInterval = 0,
        readStatus: UserTransaction.MessageReadStatus = .init(owner: false, requester: false)
    ) -> UserTransaction {
        let copyOwner: User = owner ?? camille
        let asker: User = requester ?? myself
        let item: InventoryItem = Fixture.inventoryItem(
            id: "item-\(id)",
            ownerId: copyOwner._id,
            edition: Fixture.edition(uri: "isbn:\(id)")
        )
        let transaction: UserTransaction = .init(
            _id: id,
            _rev: "1",
            item: item,
            owner: copyOwner,
            requester: asker,
            type: .lending,
            created: .init(timeIntervalSince1970: 0),
            messages: [],
            state: state,
            actions: [.init(action: state, timestamp: .init(timeIntervalSince1970: lastAction))],
            readStatus: readStatus
        )
        context.insert(item)
        context.insert(transaction)
        return transaction
    }
}
