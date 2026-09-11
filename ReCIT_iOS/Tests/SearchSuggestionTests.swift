//
//  SearchSuggestionTests.swift
//  ReCIT_iOSTests
//
//  The three ways on to inventaire.io: that there are three of them, that they come in the same
//  order every time, and — the reason this type exists at all — that each one carries the entity
//  types its request will ask for. A row labelled « Auteur·ices contenant mont » that searches
//  books is the failure this suite is here to catch.
//
//  Pure and network-free. The one thing deliberately not asserted is the wording of a label: the
//  sentences live in the catalogue, and a test that pinned them would break on a translation
//  rather than on a bug. What is asserted is the emphasis, through the pure helper that applies
//  it to a sentence handed in.
//
//  See PRD 0012.
//

import Foundation
import SwiftUI
import Testing
import UIKit
@testable import ReCIT_iOS

@Suite("SearchSuggestion")
struct SearchSuggestionTests {

    // MARK: - The three, and their order

    @Test("Past the threshold there are three suggestions, books then people then everything")
    func threeSuggestionsInAStableOrder() {
        let suggestions: [SearchSuggestion] = SearchSuggestion.suggestions(for: "monte cristo")

        #expect(suggestions.map(\.kind) == [.works, .humans, .everything])
    }

    @Test("Each suggestion asks inventaire.io for the types its row names")
    func eachSuggestionCarriesItsEntityTypes() {
        let suggestions: [SearchSuggestion] = SearchSuggestion.suggestions(for: "monte cristo")

        #expect(suggestions.first(where: { $0.kind == .works })?.entityTypes == [.works])
        #expect(suggestions.first(where: { $0.kind == .humans })?.entityTypes == [.humans])
        #expect(suggestions.first(where: { $0.kind == .everything })?.entityTypes == [.humans, .works])
    }

    @Test("Every suggestion carries the query it was built from, trimmed")
    func everySuggestionCarriesTheQuery() {
        let suggestions: [SearchSuggestion] = SearchSuggestion.suggestions(for: "  monte  ")

        #expect(suggestions.allSatisfy { $0.query == "monte" })
        #expect(Set(suggestions.map(\.id)).count == suggestions.count)
    }

    @Test("Each one draws a symbol that exists, and no two draw the same one")
    func eachSuggestionDrawsItsOwnSymbol() {
        let suggestions: [SearchSuggestion] = SearchSuggestion.suggestions(for: "monte")

        for suggestion in suggestions {
            #expect(UIImage(systemName: suggestion.glyph) != nil, "unknown symbol \(suggestion.glyph)")
        }
        #expect(Set(suggestions.map(\.glyph)).count == suggestions.count)
    }

    // MARK: - The threshold

    @Test("Below three characters there is nothing to suggest")
    func nothingToSuggestBelowTheThreshold() {
        #expect(SearchSuggestion.suggestions(for: "").isEmpty)
        #expect(SearchSuggestion.suggestions(for: "mo").isEmpty)
        #expect(SearchSuggestion.suggestions(for: "   ").isEmpty)
    }

    @Test("The threshold is the one SearchPhase publishes, wherever it is set")
    func thresholdIsTheOneSearchPhasePublishes() {
        let atThreshold: String = .init(repeating: "a", count: SearchPhase.minimumQueryLength)
        let justBelow: String = .init(atThreshold.dropLast())

        #expect(SearchSuggestion.suggestions(for: atThreshold).count == 3)
        #expect(SearchSuggestion.suggestions(for: justBelow).isEmpty)
    }

    // MARK: - What the keyboard sends

    @Test("The keyboard's search key sends the query against both books and people")
    func keyboardSubmissionAsksForBoth() {
        let submission: SearchSuggestion? = .everything(for: "  monte cristo ")

        #expect(submission?.kind == .everything)
        #expect(submission?.query == "monte cristo")
        #expect(submission?.entityTypes == [.humans, .works])
    }

    @Test("The keyboard's search key sends nothing below the threshold")
    func keyboardSubmissionRespectsTheThreshold() {
        #expect(SearchSuggestion.everything(for: "mo") == nil)
        #expect(SearchSuggestion.everything(for: "   ") == nil)
    }

    // MARK: - The query, in bold

    @Test("The query is emphasised inside the sentence that holds it")
    func theQueryIsEmphasisedInsideTheSentence() {
        let label: AttributedString = SearchSuggestion.emphasising("mont", in: "Livres contenant mont")
        let emphasised: [String] = label.runs
            .filter { $0.inlinePresentationIntent == .stronglyEmphasized }
            .map { String(label[$0.range].characters) }

        #expect(emphasised == ["mont"])
    }

    @Test("A query the sentence spells with accents or capitals is still emphasised")
    func emphasisIgnoresCaseAndAccents() {
        let label: AttributedString = SearchSuggestion.emphasising("emile", in: "Auteur·ices contenant Émile")
        let isEmphasised: Bool = label.runs.contains { $0.inlinePresentationIntent == .stronglyEmphasized }

        #expect(isEmphasised)
    }

    @Test("A sentence that does not hold the query is left alone rather than mangled")
    func aSentenceWithoutTheQueryIsLeftAlone() {
        let label: AttributedString = SearchSuggestion.emphasising("zola", in: "Livres contenant hugo")

        #expect(label.runs.allSatisfy { $0.inlinePresentationIntent == nil })
        #expect(String(label.characters) == "Livres contenant hugo")
    }
}

// MARK: - The emphasis, as it actually draws
//
// The suggestions read in the app's own Alegreya, and a bold run only shows if that family
// resolves a bold face — a custom font that does not simply draws the whole sentence flat, with
// nothing in the logs to say so. This suite renders the label to check that the emphasis
// survives the font it is drawn in, which is the only part of « la requête en gras » that a
// value test cannot see.

@MainActor
@Suite("SearchSuggestion, drawn")
struct SearchSuggestionRenderingTests {

    @Test("An emphasised query draws differently from the same sentence without it")
    func emphasisSurvivesTheAppSFont() throws {
        DesignSystem.start()

        let sentence: String = "Livres contenant mont"
        let plain: CGSize = try #require(render(.init(sentence)))
        let emphasised: CGSize = try #require(render(SearchSuggestion.emphasising("mont", in: sentence)))

        #expect(emphasised.width != plain.width)
    }

    private func render(_ label: AttributedString) -> CGSize? {
        let renderer: ImageRenderer = .init(
            content: Text(label)
                .textStyle(.content300)
                .fixedSize()
        )

        return renderer.uiImage?.size
    }
}
