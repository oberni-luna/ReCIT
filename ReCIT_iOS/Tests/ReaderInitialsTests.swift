//
//  ReaderInitialsTests.swift
//  ReCIT_iOSTests
//
//  The letters a reader without a photo is drawn with (PRD 0019, Q20). One letter per word of
//  the handle when it has several, its first two letters otherwise; uppercased, accents kept.
//

import Testing
@testable import ReCIT_iOS

@Suite("Reader initials")
struct ReaderInitialsTests {

    @Test(
        "The handles of the acceptance criteria",
        arguments: [
            ("olivier_berni", "OB"),
            ("Léa", "LÉ"),
            ("Aïcha", "AÏ"),
            ("JeanLuc", "JL"),
            ("", "")
        ]
    )
    func acceptanceCriteria(username: String, initials: String) {
        #expect(ReaderInitials.of(username) == initials)
    }

    @Test(
        "Every separator cuts a word",
        arguments: [
            ("olivier.berni", "OB"),
            ("olivier-berni", "OB"),
            ("olivier berni", "OB"),
            ("olivier\tberni", "OB"),
            ("ÉloïseMartin", "ÉM")
        ]
    )
    func separators(username: String, initials: String) {
        #expect(ReaderInitials.of(username) == initials)
    }

    @Test("Two letters at most, from the first two words")
    func twoLettersAtMost() {
        #expect(ReaderInitials.of("jean-luc_de.la fontaine") == "JL")
        // The e2e account: a case change, then an underscore.
        #expect(ReaderInitials.of("OlivierB_test2") == "OB")
    }

    @Test("Separators at the edges or doubled make no empty word")
    func strayedSeparators() {
        #expect(ReaderInitials.of("_olivier_") == "OL")
        #expect(ReaderInitials.of("olivier__berni") == "OB")
        #expect(ReaderInitials.of(" - ") == "")
    }

    @Test("An uppercase run is one word, not one per letter")
    func uppercaseRun() {
        #expect(ReaderInitials.of("ALAIN") == "AL")
        #expect(ReaderInitials.of("OBerni") == "OB")
    }

    @Test("A single character is its own initial")
    func singleCharacter() {
        #expect(ReaderInitials.of("a") == "A")
        #expect(ReaderInitials.of("é") == "É")
    }

    @Test("An emoji is kept whole, never cut into scalars")
    func emoji() {
        #expect(ReaderInitials.of("📚") == "📚")
        #expect(ReaderInitials.of("👩‍👩‍👧") == "👩‍👩‍👧")
        #expect(ReaderInitials.of("📚_lectrice") == "📚L")
    }

    @Test("A decomposed accent stays on its letter")
    func decomposedAccent() {
        // « Aïcha » typed as A + i + combining diaeresis.
        #expect(ReaderInitials.of("Ai\u{0308}cha") == "AÏ")
    }

    @Test("Digits count as letters of a word")
    func digits() {
        #expect(ReaderInitials.of("2pac") == "2P")
        #expect(ReaderInitials.of("lectrice_93") == "L9")
    }
}
