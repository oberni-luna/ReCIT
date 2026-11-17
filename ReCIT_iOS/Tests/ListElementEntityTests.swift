//
//  ListElementEntityTests.swift
//  ReCIT_iOSTests
//
//  Created by Olivier Berni on 16/11/2026.
//

import Foundation
import SwiftData
import Testing
@testable import ReCIT_iOS

@Suite(.serialized)
@MainActor
struct ListElementEntityTests {
    @Test
    func `a work is titled by its title and bylined by its authors`() throws {
        let context: ModelContext = try TestStore.makeContext()
        let work: Work = try insertedWork(
            authors: ["Ursula K. Le Guin", "", "Alain Dorémieux"],
            subtitle: "roman",
            in: context
        )

        let entity: ListElementEntity = .work(work)

        #expect(entity.title == "Les Dépossédés")
        let byline: String = try #require(entity.byline)
        #expect(Set(byline.components(separatedBy: ", ")) == ["Ursula K. Le Guin", "Alain Dorémieux"])
    }

    @Test
    func `a work without a named author is bylined by its subtitle`() throws {
        let context: ModelContext = try TestStore.makeContext()
        let anonymous: Work = try insertedWork(authors: [""], subtitle: "roman", in: context)
        let bare: Work = try insertedWork(uri: "wd:Q2", authors: [], subtitle: nil, in: context)

        #expect(ListElementEntity.work(anonymous).byline == "roman")
        #expect(ListElementEntity.work(bare).byline == nil)
    }

    @Test
    func `an author is titled by their name and bylined by their description`() {
        let author: Author = .init(uri: "wd:Q181659", lastrevid: 1, name: "Ursula K. Le Guin", subtitle: "écrivaine américaine")
        let undescribed: Author = .init(uri: "wd:Q1", lastrevid: 1, name: "Anonyme")

        #expect(ListElementEntity.author(author).title == "Ursula K. Le Guin")
        #expect(ListElementEntity.author(author).byline == "écrivaine américaine")
        #expect(ListElementEntity.author(undescribed).byline == nil)
    }

    private func insertedWork(
        uri: String = "wd:Q1",
        authors names: [String],
        subtitle: String?,
        in context: ModelContext
    ) throws -> Work {
        let authors: [Author] = names.enumerated().map { .init(uri: "wd:A\($0.offset)", lastrevid: 1, name: $0.element) }
        authors.forEach(context.insert)
        let work: Work = .init(uri: uri, lastrevid: 1, title: "Les Dépossédés", subtitle: subtitle)
        context.insert(work)
        work.authors = authors
        try context.save()
        return work
    }
}
