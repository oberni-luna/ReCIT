//
//  EmailInvitationListTests.swift
//  ReCIT_iOSTests
//
//  Created by Olivier Berni on 18/11/2026.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@Suite
struct EmailInvitationListTests {
    private static func addresses(_ count: Int) -> String {
        (1...count).map { "reader\($0)@example.org" }.joined(separator: ", ")
    }

    @Test
    func `splits on commas, semicolons, spaces and line breaks, lowercases and keeps each address once`() {
        let list: EmailInvitationList = .init("A@b.fr, a@b.fr; c@d.fr\ne@f.fr  g@h.fr", excluding: nil)

        #expect(list.addresses == ["a@b.fr", "c@d.fr", "e@f.fr", "g@h.fr"])
        #expect(list.malformedAddresses.isEmpty)
        #expect(list.canSend)
    }

    @Test
    func `leaves my own address out, whatever its case`() {
        let list: EmailInvitationList = .init("A@b.fr, a@b.fr; Moi@Example.org, c@d.fr", excluding: "moi@example.ORG")

        #expect(list.addresses == ["a@b.fr", "c@d.fr"])
    }

    @Test(
        arguments: ["marie@", "@x.fr", "a@b", "a@@b.fr", "a@b@c.fr", "a@b..fr", "a@.fr", "a@b.", "marie"]
    )
    func `names a malformed address and cannot send`(typed: String) {
        let list: EmailInvitationList = .init("c@d.fr, \(typed)", excluding: nil)

        #expect(list.addresses == ["c@d.fr"])
        #expect(list.malformedAddresses == [typed])
        #expect(list.canSend == false)
    }

    @Test
    func `names the malformed addresses as typed, in order, each once`() {
        let list: EmailInvitationList = .init("Marie@, c@d.fr, @x.fr Marie@", excluding: nil)

        #expect(list.malformedAddresses == ["Marie@", "@x.fr"])
    }

    @Test(arguments: ["", "  \n ", ",;", "moi@example.org"])
    func `cannot send without an address`(typed: String) {
        let list: EmailInvitationList = .init(typed, excluding: "moi@example.org")

        #expect(list.addresses.isEmpty)
        #expect(list.malformedAddresses.isEmpty)
        #expect(list.canSend == false)
    }

    @Test
    func `opens the field on a search holding an address, and empty otherwise`() {
        #expect(EmailInvitationList.initialText(fromSearch: "  marie@free.fr ") == "marie@free.fr")
        #expect(EmailInvitationList.initialText(fromSearch: "marie@") == "marie@")
        #expect(EmailInvitationList.initialText(fromSearch: "camille") == "")
    }

    @Test
    func `sends fifty addresses`() {
        let list: EmailInvitationList = .init(Self.addresses(EmailInvitationList.maximumCount), excluding: nil)

        #expect(list.addresses.count == 50)
        #expect(list.canSend)
    }

    @Test
    func `cannot send fifty-one addresses`() {
        let list: EmailInvitationList = .init(Self.addresses(51), excluding: nil)

        #expect(list.addresses.count == 51)
        #expect(list.canSend == false)
    }
}
