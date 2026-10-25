//
//  NewBookDraftTests.swift
//  ReCIT_iOSTests
//
//  What the draft of a book being created does on its own, before anything is sent: which work
//  it is attached to, what its edition is called, and when it is enough to publish.
//
//  See PRD 0026.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@Suite("NewBookDraft")
struct NewBookDraftTests {

    private let ministry: WorkCandidate = .init(
        uri: "wd:Q123",
        title: "Le Ministère des Rêves",
        authors: ["Momtchil Milanov"],
        year: "2019",
        summary: nil,
        imageUrl: nil
    )

    private let future: WorkCandidate = .init(
        uri: "wd:Q102036201",
        title: "Le Ministère du futur",
        authors: ["Kim Stanley Robinson"],
        year: "2020",
        summary: nil,
        imageUrl: nil
    )

    // MARK: - Picking a work

    @Test("Picking a work attaches the edition to it, titled as the work")
    func chooseAttachesAndTitles() {
        var draft: NewBookDraft = .init(isbn: "9782494289857")

        draft.choose(ministry)

        #expect(draft.workUri == "wd:Q123")
        #expect(draft.title == "Le Ministère des Rêves")
        #expect(draft.hasAnsweredWorkQuestion)
    }

    @Test("Picking another work carries the title along, while the reader has not changed it")
    func chooseAgainFollows() {
        var draft: NewBookDraft = .init(isbn: "9782494289857")

        draft.choose(ministry)
        draft.choose(future)

        #expect(draft.title == "Le Ministère du futur")
    }

    @Test("A title the reader typed is theirs, and a later pick leaves it alone")
    func chooseKeepsATypedTitle() {
        var draft: NewBookDraft = .init(isbn: "9782494289857")

        draft.choose(ministry)
        draft.title = "Le Ministère des rêves, édition de poche"
        draft.choose(future)

        #expect(draft.title == "Le Ministère des rêves, édition de poche")
    }

    @Test("An edition of a known work is publishable with its title alone")
    func knownWorkNeedsNoAuthor() {
        var draft: NewBookDraft = .init(isbn: "9782494289857")

        draft.choose(ministry)

        #expect(draft.isPublishable)
    }

    // MARK: - Starting a work of one's own

    @Test("Creating the work from a search takes the search, with a capital")
    func startNewWorkCapitalizes() {
        var draft: NewBookDraft = .init(isbn: "9782493373052")

        draft.startNewWork(titled: " étincelles écosocialistes ")

        #expect(draft.workTitle == "Étincelles écosocialistes")
        #expect(draft.title == "Étincelles écosocialistes")
        #expect(draft.workUri == nil)
        #expect(draft.hasAnsweredWorkQuestion == false)
    }

    @Test("Leaving a picked work forgets it")
    func startNewWorkForgetsThePick() {
        var draft: NewBookDraft = .init(isbn: "9782493373052")

        draft.choose(ministry)
        draft.startNewWork(titled: "étincelles écosocialistes")

        #expect(draft.chosenWork == nil)
        #expect(draft.workUri == nil)
        #expect(draft.title == "Étincelles écosocialistes")
    }

    @Test("The edition's title follows the work's while the reader has not changed it")
    func renameWorkCarriesTheTitle() {
        var draft: NewBookDraft = .init(isbn: "9782493373052")

        draft.startNewWork(titled: "étincelles")
        draft.renameWork("Étincelles écosocialistes")

        #expect(draft.title == "Étincelles écosocialistes")
    }

    @Test("A title the reader typed stays when the work is renamed")
    func renameWorkKeepsATypedTitle() {
        var draft: NewBookDraft = .init(isbn: "9782493373052")

        draft.startNewWork(titled: "étincelles écosocialistes")
        draft.title = "Étincelles écosocialistes (poche)"
        draft.renameWork("Étincelles écosocialistes !")

        #expect(draft.title == "Étincelles écosocialistes (poche)")
    }

    @Test("A work being created needs its title, an author, and the edition's title")
    func newWorkPublishability() {
        var draft: NewBookDraft = .init(isbn: "9782493373052")
        draft.startNewWork(titled: "étincelles écosocialistes")
        #expect(draft.isPublishable == false)

        draft.authors = [.init(name: "  ")]
        #expect(draft.isPublishable == false)

        draft.authors = [.init(name: "Michael Löwy", uri: "wd:Q560474")]
        #expect(draft.isPublishable)

        draft.title = ""
        #expect(draft.isPublishable == false)
    }

    // MARK: - Where a draft reopens

    @Test("A draft reopens on the screen it was left on")
    func resumingSteps() {
        var draft: NewBookDraft = .init(isbn: "9782494289857")
        #expect(NewBookStep.resuming(draft).isEmpty)

        // The edition's form, under which the new work's screen is one touch away.
        draft.startNewWork(titled: "étincelles écosocialistes")
        #expect(NewBookStep.resuming(draft) == [.edition])

        draft.choose(ministry)
        #expect(NewBookStep.resuming(draft) == [.edition])
    }

    // MARK: - The edition's properties

    @Test("What the ISBN says becomes the edition's language, unless one was chosen")
    func languageFillsTheForm() {
        var draft: NewBookDraft = .init(isbn: "9782494289857")
        draft.language = .init(uri: "wd:Q150", code: "fr")
        #expect(draft.properties.entities(of: .language).map(\.uri) == ["wd:Q150"])

        var chosen: NewBookDraft = .init(isbn: "9782494289857")
        chosen.properties.add(.init(uri: "wd:Q1860", label: "anglais"), to: .language)
        chosen.language = .init(uri: "wd:Q150", code: "fr")
        #expect(chosen.properties.entities(of: .language).map(\.uri) == ["wd:Q1860"])
    }

    @Test("A work detached leaves the draft without one, and unpublishable")
    func detachedWork() {
        var draft: NewBookDraft = .init(isbn: "9782494289857")
        draft.choose(ministry)
        #expect(draft.isPublishable)

        draft.detachWork()
        #expect(draft.hasWork == false)
        #expect(draft.isPublishable == false)
        #expect(NewBookStep.resuming(draft).isEmpty)
    }

    @Test("A collection to create needs a publisher before the book can be published")
    func collectionNeedsPublisher() {
        var draft: NewBookDraft = .init(isbn: "9782494289857")
        draft.choose(ministry)
        draft.properties.add(.init(label: "Nature writing"), to: .collection)
        #expect(draft.isPublishable == false)

        draft.properties.add(.init(label: "Le Sous-Bois"), to: .publisher)
        #expect(draft.isPublishable)
    }

    @Test("Only the first letter is raised")
    func capitalizingFirstLetterOnly() {
        #expect(NewBookDraft.capitalizingFirstLetter("le Guin et moi") == "Le Guin et moi")
        #expect(NewBookDraft.capitalizingFirstLetter("") == "")
    }
}
