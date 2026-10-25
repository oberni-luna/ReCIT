//
//  EditionEditWorkTests.swift
//  ReCIT_iOSTests
//
//  The work half of « Modifier l'édition »: another work for the edition, a work created from the
//  form, authors added to the work. What has to exist before a claim can name it is created
//  first, once — a retry never creates an author or a work twice.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@MainActor
@Suite("EditionEdit · the work and its authors")
struct EditionEditWorkTests {

    private let editionUri: String = "inv:eba78fdf11371f4920d21cd07baa40cb"
    private let workUri: String = "inv:eba78fdf11371f4920d21cd07baa3239"

    private func edit(work: EditionWork? = nil) -> EditionEdit {
        .init(
            original: .init(
                uri: editionUri,
                title: "Penss et les plis du monde",
                isbn: "978-2-413-01351-8",
                workUri: work?.uri,
                labelLanguage: "fr"
            ),
            originalWork: work
        )
    }

    private var penss: EditionWork {
        .init(uri: workUri, title: "Penss et les plis du monde")
    }

    private let candidate: WorkCandidate = .init(
        uri: "inv:other",
        title: "Penss",
        authors: ["Jérémie Moreau"],
        year: "2019",
        summary: nil,
        imageUrl: nil
    )

    @Test("Another work replaces the edition's by name")
    func anotherWorkReplacesTheOld() {
        var edit: EditionEdit = edit(work: penss)
        edit.choose(candidate)

        #expect(edit.work?.uri == "inv:other")
        #expect(edit.isSaveable)
        #expect(edit.nextStep == .claim(.init(uri: editionUri, property: .work, oldValue: workUri, newValue: "inv:other")))

        edit.landed(edit.claimUpdates[0])

        #expect(edit.original.workUri == "inv:other")
        #expect(edit.originalWork?.title == "Penss")
        #expect(edit.hasChanges == false)
    }

    @Test("Picking the work the edition already has changes nothing")
    func sameWorkIsNoChange() {
        var edit: EditionEdit = edit(work: penss)
        edit.choose(.init(uri: workUri, title: "Penss et les plis du monde", authors: [], year: nil, summary: nil, imageUrl: nil))

        #expect(edit.hasChanges == false)
    }

    @Test("An edition with no work gets one added, not replaced")
    func workAddedToAnEditionWithout() {
        var edit: EditionEdit = edit()
        edit.choose(candidate)

        #expect(edit.claimUpdates == [.init(uri: editionUri, property: .work, oldValue: nil, newValue: "inv:other")])
    }

    @Test("A work created needs a title and an author before it can be saved")
    func newWorkNeedsTitleAndAuthor() {
        var edit: EditionEdit = edit(work: penss)
        edit.startNewWork(titled: "  penss et les plis du monde ")

        #expect(edit.newWorkTitle == "Penss et les plis du monde")
        #expect(edit.work == nil)
        #expect(edit.canAddAuthors)
        #expect(edit.isSaveable == false)

        edit.addAuthor(.init(name: "Jérémie Moreau", uri: "wd:Q3177937"))
        #expect(edit.isSaveable)

        edit.newWorkTitle = " "
        #expect(edit.isSaveable == false)
    }

    @Test("A work created goes: its new authors, then the work, then the edition's claim on it")
    func newWorkStepsInOrder() {
        var edit: EditionEdit = edit(work: penss)
        edit.startNewWork(titled: "Penss")
        edit.addAuthor(.init(name: "Jérémie Moreau"))
        edit.addAuthor(.init(name: "Someone Known", uri: "wd:Q1"))

        guard case .createAuthor(let id, let label, let language) = edit.nextStep else {
            Issue.record("expected the new author first, got \(String(describing: edit.nextStep))")
            return
        }
        #expect(label == "Jérémie Moreau")
        #expect(language == "fr")

        edit.authorCreated(id: id, uri: "inv:author")
        #expect(edit.nextStep == .createWork(label: "Penss", language: "fr", authorUris: ["inv:author", "wd:Q1"]))

        edit.workCreated(uri: "inv:work")
        #expect(edit.addedAuthors.isEmpty)
        #expect(edit.nextStep == .claim(.init(uri: editionUri, property: .work, oldValue: workUri, newValue: "inv:work")))

        edit.landed(edit.claimUpdates[0])
        #expect(edit.nextStep == nil)
        #expect(edit.originalWork?.authors.map(\.trimmedName) == ["Jérémie Moreau", "Someone Known"])
    }

    @Test("An author added to the edition's work is claimed on the work, then listed on it")
    func authorAddedToTheWork() {
        var edit: EditionEdit = edit(work: penss)
        edit.addAuthor(.init(name: "Jérémie Moreau", uri: "wd:Q3177937"))

        #expect(edit.isSaveable)
        #expect(edit.claimUpdates == [.init(uri: workUri, property: .author, oldValue: nil, newValue: "wd:Q3177937")])

        edit.landed(edit.claimUpdates[0])

        #expect(edit.addedAuthors.isEmpty)
        #expect(edit.originalWork?.authors.map(\.uri) == ["wd:Q3177937"])
        #expect(edit.hasChanges == false)
    }

    @Test("An author already on the work, or already added, is not added again")
    func authorsAreNotDoubled() {
        var withAuthor: EditionWork = penss
        withAuthor.authors = [.init(name: "Jérémie Moreau", uri: "wd:Q3177937")]
        var edit: EditionEdit = edit(work: withAuthor)

        edit.addAuthor(.init(name: "Jérémie Moreau", uri: "wd:Q3177937"))
        edit.addAuthor(.init(name: "jérémie moreau"))
        #expect(edit.addedAuthors.isEmpty)

        edit.addAuthor(.init(name: "Lucie Durand"))
        edit.addAuthor(.init(name: "Lucie Durand"))
        #expect(edit.addedAuthors.count == 1)
    }

    @Test("A Wikidata work takes no author from here")
    func wikidataWorkTakesNoAuthor() {
        var edit: EditionEdit = edit(work: .init(uri: "wd:Q1", title: "Le Comte de Monte-Cristo"))

        #expect(edit.canAddAuthors == false)

        edit.choose(candidate)
        #expect(edit.canAddAuthors)
    }

    @Test("A created author keeps its uri, and the retry does not create it again")
    func createdAuthorIsNotCreatedTwice() {
        var edit: EditionEdit = edit(work: penss)
        edit.addAuthor(.init(name: "Lucie Durand"))

        guard case .createAuthor(let id, _, _) = edit.nextStep else {
            Issue.record("expected the author to be created first")
            return
        }
        edit.authorCreated(id: id, uri: "inv:lucie")

        #expect(edit.nextStep == .claim(.init(uri: workUri, property: .author, oldValue: nil, newValue: "inv:lucie")))
    }
}
