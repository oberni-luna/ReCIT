//
//  ContentLanguageTests.swift
//  ReCIT_iOSTests
//
//  The phone's language, reduced to the bare code inventaire.io's `lang` takes.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@Suite("ContentLanguage")
struct ContentLanguageTests {

    @Test("A region or a script is dropped, the language kept")
    func bareCode() {
        #expect(ContentLanguage.code(of: "en-FR") == "en")
        #expect(ContentLanguage.code(of: "pt-BR") == "pt")
        #expect(ContentLanguage.code(of: "zh-Hant-TW") == "zh")
        #expect(ContentLanguage.code(of: "fr") == "fr")
    }

    @Test("No identifier is no language")
    func noIdentifier() {
        #expect(ContentLanguage.code(of: nil) == nil)
        #expect(ContentLanguage.code(of: "") == nil)
    }

    @Test("The phone's first language is the one asked for")
    func preferredIsThePhones() {
        #expect(ContentLanguage.preferred == ContentLanguage.code(of: Locale.preferredLanguages.first) ?? "fr")
    }
}
