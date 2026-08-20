//
//  SortDraftID.swift
//  ReCIT_iOS
//
//  The client id an étagère drafted on the sorting surface carries until it is
//  created for real.
//
//  Prefixed, exactly as `OptimisticID` prefixes an optimistic placeholder, and for
//  the same reason: the write plan decides what to create by asking whether a
//  section is a draft, and a bare UUID sitting where a CouchDB `_id` is expected is
//  a mistake nothing would catch. See ADR 0001 / PRD 0008.
//

import Foundation

enum SortDraftID {
    static let prefix: String = "draft:"

    static func make() -> String { "\(prefix)\(UUID().uuidString)" }

    static func isDraft(_ id: String) -> Bool { id.hasPrefix(prefix) }
}
