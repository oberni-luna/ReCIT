//
//  ListAdditionPlan.swift
//  ReCIT_iOS
//
//  What adding to a list comes down to, once the reader has said which works they want: the
//  ones the list does not hold yet, or — when it holds them all — the one to show instead.
//
//  **inventaire.io keeps a work only once in a list.** `PUT /api/lists/add-elements` answers an
//  uri the list already holds with `alreadyInList` and creates nothing, so a « add it twice » is
//  not a thing the app can offer. What it can do is not pretend: the uris already there are left
//  out of the request, and when nothing is left the reader is told the book is there and taken
//  to it.
//
//  Pure, so the scanner and the search agree on it and the rule is tested once. See PRD 0029.
//

import Foundation

enum ListAdditionPlan: Equatable {
    /// Add these uris, in the order they were chosen.
    case add([String])
    /// Every chosen uri is already in the list: show this one.
    case alreadyInList(String)
    /// Nothing was chosen.
    case nothing

    static func plan(chosen: [String], existing: Set<String>) -> ListAdditionPlan {
        var seen: Set<String> = []
        let distinct: [String] = chosen.filter { seen.insert($0).inserted }
        guard let first = distinct.first else { return .nothing }

        let missing: [String] = distinct.filter { existing.contains($0) == false }
        return missing.isEmpty ? .alreadyInList(first) : .add(missing)
    }
}
