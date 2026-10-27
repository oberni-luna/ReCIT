//
//  MergeResponseDTO.swift
//  ReCIT_iOS
//
//  The answer of `PUT /api/entities/merge`: `{ ok: true }`, or `{ ok: true, taskId }` when the
//  server filed a task instead of merging. See `MergeOutcome`. PRD 0028.
//

import Foundation

struct MergeResponseDTO: Codable {
    let ok: Bool
    let taskId: String?
}
