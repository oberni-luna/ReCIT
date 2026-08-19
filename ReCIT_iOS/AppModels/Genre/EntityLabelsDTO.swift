//
//  EntityLabelsDTO.swift
//  ReCIT_iOS
//
//  Slim decoding of `by-uris` when only `attributes=labels` is asked for.
//  `EntityResultDTO` cannot be reused here: that response carries no `type`,
//  no `claims` and no `descriptions`, all of which it requires. Genre uris are
//  fetched by the hundred, so asking for the full payload just to read one
//  label would be a large waste of bandwidth.
//

import Foundation

struct EntityLabelsResultsDTO: Codable {
    let entities: [String: EntityLabelsDTO]
}

struct EntityLabelsDTO: Codable {
    let uri: String
    let labels: [String: String]
}
