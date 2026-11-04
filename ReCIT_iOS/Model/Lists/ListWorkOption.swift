//
//  ListWorkOption.swift
//  ReCIT_iOS
//
//  One work an edition holds, as the reader picks it when the edition holds several — a
//  collection of short stories, an omnibus. A value, so the choice outlives the edition it was
//  read from and the dialog never touches SwiftData. See PRD 0029.
//

import Foundation

struct ListWorkOption: Identifiable, Hashable {
    let uri: String
    let title: String

    var id: String { uri }
}
