//
//  NewBookDraftsTests.swift
//  ReCIT_iOSTests
//
//  Created by Olivier Berni on 06/11/2026.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@Suite
struct NewBookDraftsTests {
    @Test
    func `a draft reopens on the same query, and another query starts blank`() {
        var drafts: NewBookDrafts = .init()
        var draft: NewBookDraft = drafts.draft(for: .search(query: "le ministère des rêves"))
        draft.title = "Le Ministère des Rêves"

        drafts.remember(draft, for: .search(query: "le ministère des rêves"))

        #expect(drafts.draft(for: .search(query: "le ministère des rêves")).title == "Le Ministère des Rêves")
        #expect(drafts.draft(for: .search(query: "le ministère du futur")).title.isEmpty)
    }

    @Test
    func `a query and a barcode keep their drafts apart`() {
        var drafts: NewBookDrafts = .init()
        var draft: NewBookDraft = drafts.draft(for: .scan(isbn: "9782070368228"))
        draft.title = "Scanned"

        drafts.remember(draft, for: .scan(isbn: "9782070368228"))

        #expect(drafts.draft(for: .search(query: "9782070368228")).title.isEmpty)
    }

    @Test
    func `a published draft is forgotten`() {
        var drafts: NewBookDrafts = .init()
        var draft: NewBookDraft = drafts.draft(for: .search(query: "dune"))
        draft.title = "Dune"
        drafts.remember(draft, for: .search(query: "dune"))

        drafts.forget(.search(query: "dune"))

        #expect(drafts.draft(for: .search(query: "dune")).title.isEmpty)
    }
}
