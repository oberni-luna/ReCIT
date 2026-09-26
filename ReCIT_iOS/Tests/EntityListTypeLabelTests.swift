//
//  EntityListTypeLabelTests.swift
//  ReCIT_iOSTests
//
//  The list form's type picker shows a word from the catalogue, not inventaire.io's raw value.
//  Pure and network-free.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@Suite
struct EntityListTypeLabelTests {
    @Test(arguments: EntityListType.allCases)
    func labelIsACatalogueEntryNotTheRawValue(type: EntityListType) {
        var resource: LocalizedStringResource = type.label
        resource.locale = .init(identifier: "fr")
        let shown: String = String(localized: resource)

        #expect(shown != type.rawValue)
        #expect(shown != String(describing: type.label.key))
    }

    @Test
    func frenchLabelsAreTheOnesAskedFor() {
        let french: [EntityListType: String] = EntityListType.allCases.reduce(into: [:]) { labels, type in
            var resource: LocalizedStringResource = type.label
            resource.locale = .init(identifier: "fr")
            labels[type] = String(localized: resource)
        }

        #expect(french[.work] == "Œuvre")
        #expect(french[.author] == "Auteur·ice")
        #expect(french[.publisher] == "Maison d'édition")
    }
}
