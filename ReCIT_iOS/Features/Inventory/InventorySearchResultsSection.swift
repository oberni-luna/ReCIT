//
//  InventorySearchResultsSection.swift
//  ReCIT_iOS
//
//  What inventaire.io answered, in two groups: the books first, the people after. One flat list
//  would interleave a novel, a novelist and another novel by rank, and rank is the server's
//  business, not a reading order — grouping by type is what lets the eye go straight to the half
//  of the answer it came for.
//
//  Each header states its count, so a query that came back with forty books says so before the
//  scroll does.
//
//  There is deliberately nothing here for "loading", "nothing found" or "the call failed": the
//  first belongs to the field, the failure goes out through `AppErrorReporter` like every other
//  background failure in the app, and what to *say* in the other two is issue 0076's question.
//
//  See PRD 0012.
//

import SwiftUI

struct InventorySearchResultsSection: View {
    let results: [SearchResult]

    private var works: [SearchResult] {
        results.filter { $0.type == .works }
    }

    private var humans: [SearchResult] {
        results.filter { $0.type == .humans }
    }

    var body: some View {
        let workResults: [SearchResult] = works
        let humanResults: [SearchResult] = humans

        InventorySearchResultGroup(
            title: "inventory.search.results.works \(workResults.count)",
            results: workResults
        )
        InventorySearchResultGroup(
            title: "inventory.search.results.humans \(humanResults.count)",
            results: humanResults
        )
    }
}
