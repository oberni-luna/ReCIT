//
//  NewBookOriginTests.swift
//  ReCIT_iOSTests
//
//  Created by Olivier Berni on 06/11/2026.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@Suite
struct NewBookOriginTests {
    @Test
    func `a text query opens the work search on it, with no ISBN`() {
        let origin: NewBookOrigin = .search(query: " le ministère des rêves ")

        #expect(origin.workQuery == "le ministère des rêves")
        #expect(origin.isbn == nil)
        #expect(origin.blankDraft.isbn.isEmpty)
        #expect(origin.isISBNEditable)
    }

    @Test
    func `an ISBN query fills the ISBN and leaves the work search empty`() {
        let origin: NewBookOrigin = .search(query: "978-2-07-036822-8")

        #expect(origin.workQuery.isEmpty)
        #expect(origin.isbn == "9782070368228")
        #expect(origin.blankDraft.isbn == "9782070368228")
        #expect(origin.isISBNEditable)
    }

    @Test
    func `a scan keeps its ISBN read-only and its work search empty`() {
        let origin: NewBookOrigin = .scan(isbn: "9782494289857")

        #expect(origin.workQuery.isEmpty)
        #expect(origin.blankDraft.isbn == "9782494289857")
        #expect(origin.isISBNEditable == false)
    }
}
