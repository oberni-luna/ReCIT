//
//  EditionMergeRequest.swift
//  ReCIT_iOS
//
//  The body of `PUT /api/entities/merge`: `from`, the `inv:` edition that becomes a redirection,
//  and `to`, the edition kept (`inv:` or `wd:`). PRD 0028.
//

import Foundation

struct EditionMergeRequest: Codable, Equatable, Sendable {
    let from: String
    let to: String
}
