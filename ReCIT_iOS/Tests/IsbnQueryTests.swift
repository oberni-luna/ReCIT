//
//  IsbnQueryTests.swift
//  ReCIT_iOSTests
//
//  What Recherche takes for an ISBN to look up, and what it leaves to the text search.
//

import Testing
@testable import ReCIT_iOS

@Suite("IsbnQuery")
struct IsbnQueryTests {

    @Test("An ISBN-13 typed with hyphens, spaces or neither is the same thirteen digits")
    func thirteen() {
        #expect(IsbnQuery.isbn(in: "978-2-234-09688-2") == "9782234096882")
        #expect(IsbnQuery.isbn(in: "978 2 234 09688 2") == "9782234096882")
        #expect(IsbnQuery.isbn(in: "  9782234096882 ") == "9782234096882")
        #expect(IsbnQuery.isbn(in: "979-10-90724-00-6") == "9791090724006")
    }

    @Test("An ISBN-10 is looked up as the ISBN-13 it stands for")
    func ten() {
        #expect(IsbnQuery.isbn(in: "2-07-036822-X") == "9782070368228")
        #expect(IsbnQuery.isbn(in: "2-07-036822-x") == "9782070368228")
        #expect(IsbnQuery.isbn(in: "0198534531") == "9780198534532")
    }

    @Test("A wrong check digit is not an ISBN")
    func wrongCheckDigit() {
        #expect(IsbnQuery.isbn(in: "978-2-234-09688-1") == nil)
        #expect(IsbnQuery.isbn(in: "2-07-036822-1") == nil)
    }

    @Test("Thirteen digits outside the 978 and 979 prefixes are not an ISBN")
    func notABookland() {
        #expect(IsbnQuery.isbn(in: "4006381333931") == nil)
    }

    @Test("Words with digits in them go to the text search")
    func words() {
        #expect(IsbnQuery.isbn(in: "Dune 1965") == nil)
        #expect(IsbnQuery.isbn(in: "isbn 9782234096882") == nil)
        #expect(IsbnQuery.isbn(in: "1984") == nil)
        #expect(IsbnQuery.isbn(in: "") == nil)
    }

    @Test("An X anywhere but last is not an ISBN-10")
    func misplacedX() {
        #expect(IsbnQuery.isbn(in: "2-07-03682X-2") == nil)
    }
}
