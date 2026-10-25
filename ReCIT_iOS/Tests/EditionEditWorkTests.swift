//
//  EditionEditWorkTests.swift
//  ReCIT_iOSTests
//
//  The works of « Modifier l'édition »: listed, added from the search or created, detached with
//  a swipe, renamed and given or relieved of authors in « Modifier l'œuvre ». What has to exist
//  before a claim can name it is created first, once — a retry never creates an author or a work
//  twice.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@MainActor
@Suite("EditionEdit · the works and their authors")
struct EditionEditWorkTests {

    private let editionUri: String = "inv:eba78fdf11371f4920d21cd07baa40cb"
    private let workUri: String = "inv:eba78fdf11371f4920d21cd07baa3239"

    private func edit(works: [EditionWork] = []) -> EditionEdit {
        .init(
            original: .init(
                uri: editionUri,
                title: "Penss et les plis du monde",
                isbn: "978-2-413-01351-8",
                workUris: works.map(\.uri),
                labelLanguage: "fr"
            ),
            originalWorks: works
        )
    }

    private var penss: EditionWork {
        .init(uri: workUri, title: "Penss et les plis du monde", titleLanguage: "fr")
    }

    private let candidate: WorkCandidate = .init(
        uri: "wd:Q1",
        title: "Penss",
        authors: ["Jérémie Moreau"],
        year: "2019",
        summary: nil,
        imageUrl: nil
    )

    @Test("A work added from the search is claimed on the edition, and listed once")
    func workAdded() {
        var edit: EditionEdit = edit(works: [penss])
        edit.addWork(candidate)
        edit.addWork(candidate)

        #expect(edit.works.map(\.uri) == [workUri, "wd:Q1"])
        #expect(edit.isSaveable)
        #expect(edit.nextStep == .claim(.init(uri: editionUri, property: .work, oldValue: nil, newValue: "wd:Q1")))

        edit.landed(edit.claimUpdates[0])

        #expect(edit.original.workUris == [workUri, "wd:Q1"])
        #expect(edit.hasChanges == false)
    }

    @Test("A work detached is unclaimed; with none left the edition cannot be saved")
    func workDetached() {
        var edit: EditionEdit = edit(works: [penss])
        edit.addWork(candidate)
        edit.landed(edit.claimUpdates[0])

        edit.detachWork(id: edit.works[0].id)
        #expect(edit.claimUpdates == [.init(uri: editionUri, property: .work, oldValue: workUri, newValue: nil)])
        #expect(edit.isSaveable)

        edit.detachWork(id: edit.works[0].id)
        #expect(edit.hasChanges)
        #expect(edit.isSaveable == false)
    }

    @Test("A work created needs a title and an author before it can be saved")
    func newWorkNeedsTitleAndAuthor() {
        var edit: EditionEdit = edit(works: [penss])
        let id: UUID = edit.startNewWork(titled: "  penss et les plis du monde ")
        let index: Int = edit.works.firstIndex { $0.id == id }!

        #expect(edit.works[index].title == "Penss et les plis du monde")
        #expect(edit.works[index].isNew)
        #expect(edit.isSaveable == false)

        edit.works[index].addAuthor(.init(name: "Jérémie Moreau", uri: "wd:Q3177937"))
        #expect(edit.isSaveable)

        edit.works[index].title = " "
        #expect(edit.isSaveable == false)
    }

    @Test("A work created goes: its new authors, then the work, then the edition's claim on it")
    func newWorkStepsInOrder() {
        var edit: EditionEdit = edit()
        let id: UUID = edit.startNewWork(titled: "Penss")
        edit.works[0].addAuthor(.init(name: "Jérémie Moreau"))
        edit.works[0].addAuthor(.init(name: "Someone Known", uri: "wd:Q1"))

        guard case .createAuthor(let authorId, let label, let language) = edit.nextStep else {
            Issue.record("expected the new author first, got \(String(describing: edit.nextStep))")
            return
        }
        #expect(label == "Jérémie Moreau")
        #expect(language == "fr")

        edit.authorCreated(id: authorId, uri: "inv:author")
        #expect(edit.nextStep == .createWork(id: id, label: "Penss", language: "fr", authorUris: ["inv:author", "wd:Q1"]))

        edit.workCreated(id: id, uri: "inv:work")
        #expect(edit.nextStep == .claim(.init(uri: editionUri, property: .work, oldValue: nil, newValue: "inv:work")))

        edit.landed(edit.claimUpdates[0])
        #expect(edit.nextStep == nil)
        #expect(edit.works[0].original?.authors.map(\.trimmedName) == ["Jérémie Moreau", "Someone Known"])
        #expect(edit.hasChanges == false)
    }

    @Test("Authors added to and taken from a work are claimed on the work")
    func authorsOfAWork() {
        var withAuthor: EditionWork = penss
        withAuthor.authors = [.init(name: "Jérémie Moreau", uri: "wd:Q3177937")]
        var edit: EditionEdit = edit(works: [withAuthor])

        edit.works[0].addAuthor(.init(name: "Lucie Durand", uri: "inv:lucie"))
        edit.works[0].removeAuthors(atOffsets: [0])

        #expect(edit.isSaveable)
        #expect(edit.claimUpdates == [
            .init(uri: workUri, property: .author, oldValue: nil, newValue: "inv:lucie"),
            .init(uri: workUri, property: .author, oldValue: "wd:Q3177937", newValue: nil)
        ])

        edit.landed(edit.claimUpdates[0])
        edit.landed(edit.claimUpdates[0])

        #expect(edit.works[0].original?.authors.map(\.uri) == ["inv:lucie"])
        #expect(edit.hasChanges == false)
    }

    @Test("A work renamed goes out as a label, in the language of the title it had, after the claims")
    func workRenamed() {
        var edit: EditionEdit = edit(works: [penss])
        edit.works[0].title = "Penss"
        edit.title = "Penss (poche)"

        #expect(edit.nextStep == .claim(.init(uri: editionUri, property: .title, oldValue: "Penss et les plis du monde", newValue: "Penss (poche)")))
        edit.landed(edit.claimUpdates[0])

        #expect(edit.nextStep == .label(.init(uri: workUri, lang: "fr", value: "Penss")))
        edit.landed(edit.labelUpdates[0])

        #expect(edit.nextStep == nil)
        #expect(edit.hasChanges == false)
    }

    @Test("An author already on the work is not added again")
    func authorsAreNotDoubled() {
        var withAuthor: EditionWork = penss
        withAuthor.authors = [.init(name: "Jérémie Moreau", uri: "wd:Q3177937")]
        var edit: EditionEdit = edit(works: [withAuthor])

        edit.works[0].addAuthor(.init(name: "Jérémie Moreau", uri: "wd:Q3177937"))
        edit.works[0].addAuthor(.init(name: "jérémie moreau"))
        #expect(edit.works[0].authors.count == 1)
        #expect(edit.hasChanges == false)
    }

    @Test("A Wikidata work is shown and not changed")
    func wikidataWorkIsReadOnly() {
        var edit: EditionEdit = edit(works: [.init(uri: "wd:Q1", title: "Le Comte de Monte-Cristo")])

        edit.works[0].addAuthor(.init(name: "Alexandre Dumas"))
        edit.works[0].title = "Le Comte"

        #expect(edit.works[0].isEditable == false)
        #expect(edit.works[0].authors.isEmpty)
        #expect(edit.labelUpdates.isEmpty)
    }

    @Test("A work the description left out is still listed, and not detached")
    func undescribedWorkStays() {
        let edit: EditionEdit = .init(
            original: .init(uri: editionUri, title: "Penss", workUris: [workUri, "inv:other"]),
            originalWorks: [penss]
        )

        #expect(edit.works.map(\.uri) == [workUri, "inv:other"])
        #expect(edit.hasChanges == false)
        #expect(edit.claimUpdates.isEmpty)
    }

    @Test("A created author keeps its uri, and the retry does not create it again")
    func createdAuthorIsNotCreatedTwice() {
        var edit: EditionEdit = edit(works: [penss])
        edit.works[0].addAuthor(.init(name: "Lucie Durand"))

        guard case .createAuthor(let id, _, _) = edit.nextStep else {
            Issue.record("expected the author to be created first")
            return
        }
        edit.authorCreated(id: id, uri: "inv:lucie")

        #expect(edit.nextStep == .claim(.init(uri: workUri, property: .author, oldValue: nil, newValue: "inv:lucie")))
    }
}
