//
//  ListVisibilityLabelTests.swift
//  ReCIT_iOSTests
//
//  Who may see a list, as the Présentation tab says it, from inventaire.io's visibility keys.
//  Pure and network-free.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@Suite
struct ListVisibilityLabelTests {
    private func french(_ visibility: [VisibilityAttributes]) -> String {
        var resource: LocalizedStringResource = ListVisibilityLabel.label(for: visibility)
        resource.locale = .init(identifier: "fr")
        return String(localized: resource)
    }

    @Test
    func noKeyIsOnlyMe() {
        #expect(french([]) == "Moi seul·e")
    }

    @Test
    func friendsAndGroupsAreNamedApartAndTogether() {
        #expect(french([.friends]) == "Mes amis")
        #expect(french([.groups]) == "Mes groupes")
        #expect(french([.friends, .groups]) == "Mes amis et mes groupes")
        #expect(french([.groups, .friends]) == "Mes amis et mes groupes")
    }

    @Test
    func publicWinsOverTheRest() {
        #expect(french([.public]) == "Tout le monde")
        #expect(french([.friends, .public, .groups]) == "Tout le monde")
    }
}
