//
//  EditionLanguageFilterTests.swift
//  ReCIT_iOSTests
//
//  Which editions « Éditions » shows in one language, what its menu offers, and which language
//  it opens on.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@Suite("Edition language filter")
struct EditionLanguageFilterTests {

    @Test("The menu offers every edition, then the languages by number of editions, then those without one")
    func options() {
        let options: [EditionLanguageFilterOption] = EditionLanguageFilter.options(of: ["fr", "en", nil, "EN", "de", "", "en", "fr"])

        #expect(options == [
            .init(language: .all, count: 8),
            .init(language: .code("en"), count: 3),
            .init(language: .code("fr"), count: 2),
            .init(language: .code("de"), count: 1),
            .init(language: .unspecified, count: 2)
        ])
    }

    @Test("No « Langue non renseignée » when every edition has a language")
    func noUnspecified() {
        #expect(EditionLanguageFilter.options(of: ["fr", "fr"]).map(\.language) == [.all, .code("fr")])
    }

    @Test("The phone's language when the work has editions in it, every edition otherwise")
    func preferred() {
        let options: [EditionLanguageFilterOption] = EditionLanguageFilter.options(of: ["fr", "en"])

        #expect(EditionLanguageFilter.preferred("fr", among: options) == .code("fr"))
        #expect(EditionLanguageFilter.preferred("FR", among: options) == .code("fr"))
        #expect(EditionLanguageFilter.preferred("is", among: options) == .all)
        #expect(EditionLanguageFilter.preferred(nil, among: options) == .all)
    }

    @Test("A language admits its own editions, « non renseignée » those without one")
    func admits() {
        #expect(EditionLanguageFilter.code("fr").admits("FR"))
        #expect(EditionLanguageFilter.code("fr").admits("en") == false)
        #expect(EditionLanguageFilter.code("fr").admits(nil) == false)
        #expect(EditionLanguageFilter.unspecified.admits(nil))
        #expect(EditionLanguageFilter.unspecified.admits(""))
        #expect(EditionLanguageFilter.unspecified.admits("fr") == false)
        #expect(EditionLanguageFilter.all.admits(nil))
    }

    @Test("A language is named in the phone's language, capitalized")
    func name() {
        let french: Locale = .init(identifier: "fr_FR")

        #expect(EditionLanguageFilter.name(of: "fr", in: french) == "Français")
        #expect(EditionLanguageFilter.name(of: "en", in: french) == "Anglais")
        #expect(EditionLanguageFilter.name(of: "en", in: .init(identifier: "en_US")) == "English")
    }

    @Test("The list keeps only the chosen language, and finds duplicates among it alone")
    func listing() {
        let entries: [EditionListing.Entry] = [
            .init(uri: "inv:fr1", year: "1990", title: "L'Appel de la forêt", lang: "fr"),
            .init(uri: "inv:en1", year: "1980", title: "The Call of the Wild", lang: "en"),
            .init(uri: "inv:fr2", year: "1970", title: "L'Appel de la forêt", lang: "fr"),
            .init(uri: "inv:none", year: nil, title: "The Call of the Wild", lang: nil)
        ]
        let facts: [EditionFacts] = [
            .init(uri: "inv:fr1", mergeUri: "inv:fr1", isbn: "978-2-07-033008-9"),
            .init(uri: "inv:en1", mergeUri: "inv:en1", isbn: "978-2-07-033008-9"),
            .init(uri: "inv:fr2", mergeUri: "inv:fr2"),
            .init(uri: "inv:none", mergeUri: "inv:none")
        ]

        let french: EditionListing = .make(entries: entries, facts: facts, chosen: nil, phoneLanguage: "fr")
        #expect(french.language == .code("fr"))
        #expect(french.order == ["inv:fr2", "inv:fr1"])
        #expect(french.duplicates.pairs.isEmpty)
        #expect(french.options.first == .init(language: .all, count: 4))

        let all: EditionListing = .make(entries: entries, facts: facts, chosen: .all, phoneLanguage: "fr")
        #expect(all.order.count == 4)
        #expect(all.duplicates.pairs.map(\.id) == ["inv:en1|inv:fr1"])

        let unspecified: EditionListing = .make(entries: entries, facts: facts, chosen: .unspecified, phoneLanguage: "fr")
        #expect(unspecified.order == ["inv:none"])
    }
}
