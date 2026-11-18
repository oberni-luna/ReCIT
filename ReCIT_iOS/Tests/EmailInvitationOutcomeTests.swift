//
//  EmailInvitationOutcomeTests.swift
//  ReCIT_iOSTests
//
//  Created by Olivier Berni on 18/11/2026.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@Suite
struct EmailInvitationOutcomeTests {
    private static func message(
        emails: Int = 0,
        usernames: [String] = [],
        isForGroup: Bool = false,
        language: String = "fr"
    ) -> String {
        let outcome: EmailInvitationOutcome = .init(
            invitedAddresses: (0..<emails).map { "reader\($0)@example.org" },
            existingUsernames: usernames,
            isForGroup: isForGroup
        )
        var resource: LocalizedStringResource = outcome.message
        resource.locale = .init(identifier: language)
        return String(localized: resource)
    }

    @Test
    func `counts the addresses mailed`() {
        #expect(Self.message(emails: 1) == "Invitation envoyée à 1 adresse")
        #expect(Self.message(emails: 2) == "Invitation envoyée à 2 adresses")
        #expect(Self.message(emails: 2, isForGroup: true) == "Invitation envoyée à 2 adresses")
        #expect(Self.message(emails: 2, language: "en") == "Invitation sent to 2 addresses")
    }

    @Test
    func `says the invitation left when the answer names nobody`() {
        #expect(Self.message() == "Invitation envoyée")
        #expect(Self.message(language: "en") == "Invitation sent")
    }

    @Test
    func `names the one reader already on inventaire.io`() {
        #expect(Self.message(usernames: ["camille.b"]) == "camille.b est déjà sur inventaire.io\u{202F}: demande envoyée")
        #expect(
            Self.message(usernames: ["camille.b"], isForGroup: true)
                == "camille.b est déjà sur inventaire.io\u{202F}: invitation au groupe envoyée"
        )
        #expect(Self.message(usernames: ["camille.b"], language: "en") == "camille.b is already on inventaire.io: request sent")
    }

    @Test
    func `counts the readers already on inventaire.io when there are several`() {
        let usernames: [String] = ["camille.b", "lea"]

        #expect(Self.message(usernames: usernames) == "2 lecteur·ices déjà sur inventaire.io\u{202F}: demandes envoyées")
        #expect(
            Self.message(usernames: usernames, isForGroup: true)
                == "2 lecteur·ices déjà sur inventaire.io\u{202F}: invitations envoyées"
        )
        #expect(Self.message(usernames: usernames, language: "en") == "2 readers already on inventaire.io: requests sent")
    }

    @Test
    func `joins the addresses and the one reader in one sentence`() {
        #expect(
            Self.message(emails: 2, usernames: ["camille.b"])
                == "Invitation envoyée à 2 adresses, et demande envoyée à camille.b"
        )
        #expect(
            Self.message(emails: 1, usernames: ["camille.b"], isForGroup: true)
                == "Invitation envoyée à 1 adresse, et invitation au groupe envoyée à camille.b"
        )
        #expect(
            Self.message(emails: 2, usernames: ["camille.b"], language: "en")
                == "Invitation sent to 2 addresses, and request sent to camille.b"
        )
    }

    @Test
    func `joins the addresses and the readers in one sentence`() {
        let usernames: [String] = ["camille.b", "lea", "ines"]

        #expect(
            Self.message(emails: 1, usernames: usernames)
                == "Invitation envoyée à 1 adresse, et demandes envoyées à 3 lecteur·ices"
        )
        #expect(
            Self.message(emails: 2, usernames: usernames, isForGroup: true)
                == "Invitation envoyée à 2 adresses, et invitations au groupe envoyées à 3 lecteur·ices"
        )
        #expect(
            Self.message(emails: 2, usernames: usernames, isForGroup: true, language: "en")
                == "Invitation sent to 2 addresses, and group invitations sent to 3 readers"
        )
    }

    @Test
    func `asks for a sync only when a reader already on inventaire.io was sent something`() {
        let mailedOnly: EmailInvitationOutcome = .init(
            invitedAddresses: ["a@b.fr"],
            existingUsernames: [],
            isForGroup: false
        )
        let withAccount: EmailInvitationOutcome = .init(
            invitedAddresses: [],
            existingUsernames: ["camille.b"],
            isForGroup: true
        )

        #expect(mailedOnly.hasExistingAccounts == false)
        #expect(withAccount.hasExistingAccounts)
    }
}
