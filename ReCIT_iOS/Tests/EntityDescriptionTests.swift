//
//  EntityDescriptionTests.swift
//  ReCIT_iOSTests
//
//  The line under an author's or a work's name, and the language it is read in — the phone's,
//  then French, then English, then whatever the server had. The phone's language is passed
//  explicitly, so the order does not depend on the simulator's.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@Suite("EntityDescription")
struct EntityDescriptionTests {

    private let hugo: [String: String] = [
        "fr": "romancier, poète, dramaturge, dessinateur et politicien français (1802–1885)",
        "en": "French novelist, poet, dramatist and politician (1802–1885)"
    ]

    @Test("The phone's language comes first")
    func phoneLanguageFirst() {
        #expect(EntityDescription.resolve(hugo, preferredLanguage: "en") == hugo["en"])
        #expect(EntityDescription.resolve(hugo, preferredLanguage: "fr") == hugo["fr"])
    }

    @Test("Without the phone's language, French comes first, then English")
    func frenchThenEnglish() {
        #expect(EntityDescription.resolve(hugo, preferredLanguage: "ja") == hugo["fr"])
        #expect(EntityDescription.resolve(["en": "novel", "de": "Roman"], preferredLanguage: "ja") == "novel")
    }

    @Test("The language the server fell back to is read when it is the only one")
    func serverFallbackIsRead() {
        // The shape of `wd:Q3205794` asked for in Japanese, verified against production on 2026-10-30.
        #expect(EntityDescription.resolve(["nl": "stripalbum uit onbekende serie"], preferredLanguage: "ja") == "stripalbum uit onbekende serie")
        #expect(EntityDescription.resolve(["nl": "album", "de": "Album"], preferredLanguage: "ja") == "Album")
    }

    @Test("An empty description is not one, and no description at all is nil")
    func emptyResolvesToNil() {
        #expect(EntityDescription.resolve(["en": "", "fr": "roman"], preferredLanguage: "en") == "roman")
        #expect(EntityDescription.resolve(["en": ""], preferredLanguage: "en") == nil)
        #expect(EntityDescription.resolve([:]) == nil)
        #expect(EntityDescription.resolve(nil) == nil)
    }
}
