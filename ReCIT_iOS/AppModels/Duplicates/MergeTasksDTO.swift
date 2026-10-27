//
//  MergeTasksDTO.swift
//  ReCIT_iOS
//
//  `GET /api/tasks/by-uris` — the open tasks inventaire.io's team has on each uri asked, keyed by
//  that uri, the task's *suspect*: the entity that would disappear in the merge. Every uri asked
//  comes back, with an empty list when nothing waits on it. The server's view keeps only the
//  tasks without a `state`; `state` is decoded anyway, so a closed one is never taken for open.
//
//  See PRD 0028.
//

import Foundation

struct MergeTasksDTO: Codable {
    let tasks: [String: [MergeTaskDTO]]
}

struct MergeTaskDTO: Codable {
    let type: String?
    let state: String?
    let suspectUri: String
    let suggestionUri: String
}
