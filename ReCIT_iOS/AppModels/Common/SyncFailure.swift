//
//  SyncFailure.swift
//  ReCIT_iOS
//
//  A background (optimistic / sync) failure, wrapped so observers can react to
//  each new occurrence even when the underlying error compares equal.
//

import Foundation

struct SyncFailure: Identifiable {
    let id: UUID = .init()
    let error: Error
}
