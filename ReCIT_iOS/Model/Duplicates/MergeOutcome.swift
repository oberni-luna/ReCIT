//
//  MergeOutcome.swift
//  ReCIT_iOS
//
//  What inventaire.io did with a merge it accepted. For an account that is not a dataadmin the
//  server merges at once when the two editions' works have matching labels — for two editions of
//  one work, nearly always — unless an external identifier (BnF, OCLC…) differs between them;
//  then it files a « merge » task for its team, with this account as reporter.
//
//  `{ ok: true }` is the first, `{ ok: true, taskId }` the second. The SnackBar says which.
//
//  See PRD 0028.
//

import Foundation

enum MergeOutcome: Equatable, Sendable {
    /// The edition `from` is now a redirection to the one kept.
    case merged
    /// inventaire.io's team will decide; `taskId` is the task it filed.
    case reported(taskId: String)

    /// The outcome an answer describes — `nil` for an answer that says neither.
    init?(response: MergeResponseDTO) {
        guard response.ok else { return nil }
        if let taskId = response.taskId, taskId.isEmpty == false {
            self = .reported(taskId: taskId)
        } else {
            self = .merged
        }
    }
}
