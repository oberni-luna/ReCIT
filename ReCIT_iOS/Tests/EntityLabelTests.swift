//
//  EntityLabelTests.swift
//  ReCIT_iOSTests
//
//  The name a work or an author wears, and where Wikidata keeps it now.
//
//  The phone's language is passed explicitly, so the order does not depend on the simulator's.
//
//  `mulLabelIsRead` is the case this type was written for: `wd:Q535` carries « Victor Hugo »
//  under `mul` and under neither `fr` nor `en`, and the book screen showed his portrait beside
//  an empty name.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@Suite("EntityLabel")
struct EntityLabelTests {

    @Test("The phone's language comes first")
    func phoneLanguageFirst() {
        let labels: [String: String] = ["en": "The Hunchback of Notre-Dame", "fr": "Notre-Dame de Paris", "mul": "x"]

        #expect(EntityLabel.resolve(labels, preferredLanguage: "en") == "The Hunchback of Notre-Dame")
        #expect(EntityLabel.resolve(labels, preferredLanguage: "fr") == "Notre-Dame de Paris")
        #expect(EntityLabel.language(of: labels, preferredLanguage: "en") == "en")
    }

    @Test("Without the phone's language, French comes first, then English")
    func frenchThenEnglish() {
        #expect(EntityLabel.resolve(["en": "The Wretched", "fr": "Les Misérables", "mul": "x"], preferredLanguage: "ja") == "Les Misérables")
        #expect(EntityLabel.resolve(["en": "The Wretched", "mul": "x"], preferredLanguage: "ja") == "The Wretched")
    }

    @Test("An author named only under mul is named by it")
    func mulLabelIsRead() {
        // The shape of `wd:Q535`, verified against production on 2026-10-24.
        let label: String? = EntityLabel.resolve(
            ["ru": "Виктор Гюго", "ja": "ヴィクトル・ユーゴー", "mul": "Victor Hugo"],
            originalLang: "fr",
            preferredLanguage: "fr"
        )

        #expect(label == "Victor Hugo")
    }

    @Test("Without fr, en or mul, the original language answers")
    func originalLanguageIsNext() {
        let label: String? = EntityLabel.resolve(
            ["ru": "Война и мир", "de": "Krieg und Frieden"],
            originalLang: "ru",
            preferredLanguage: "fr"
        )

        #expect(label == "Война и мир")
    }

    @Test("Any other label is picked the same way on every call")
    func lastResortIsStable() {
        let labels: [String: String] = ["ru": "Виктор Гюго", "de": "Victor Hugo", "ja": "ヴィクトル・ユーゴー"]

        #expect(EntityLabel.resolve(labels, preferredLanguage: "fr") == "Victor Hugo")
    }

    @Test("An empty label is not a name, and the next one is tried")
    func emptyStringsFallThrough() {
        #expect(EntityLabel.resolve(["fr": "", "en": "", "mul": "Victor Hugo"], preferredLanguage: "fr") == "Victor Hugo")
        #expect(EntityLabel.resolve(["fr": "", "ru": ""], preferredLanguage: "ru") == nil)
    }

    @Test("No label at all is no name")
    func namelessResolvesToNil() {
        #expect(EntityLabel.resolve([:]) == nil)
        #expect(EntityLabel.resolve(nil) == nil)
    }
}
