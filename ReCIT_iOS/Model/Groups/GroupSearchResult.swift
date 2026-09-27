//
//  GroupSearchResult.swift
//  ReCIT_iOS
//
//  A group found by name. Only what the search says: enough for a row, not for the screen.
//

import Foundation

struct GroupSearchResult: Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let description: String?
    let pictureURL: String?
}
