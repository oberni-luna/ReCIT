//
//  NewBookDraftTests.swift
//  ReCIT_iOSTests
//
//  What the draft of a book being created does on its own, before anything is sent: which work
//  it is attached to, what its edition is called, and when it is enough to publish.
//
//  See PRD 0021.
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

    @Test("Only the first letter is raised")
    func capitalizingFirstLetterOnly() {
        #expect(NewBookDraft.capitalizingFirstLetter("le Guin et moi") == "Le Guin et moi")
        #expect(NewBookDraft.capitalizingFirstLetter("") == "")
    }
}
