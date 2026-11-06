//
//  NewBookDrafts.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 06/11/2026.
//

import Foundation

/// The books being created and not yet published, each kept under where it was started from, in
/// memory only. Closing « Nouveau livre » keeps what was typed: the same barcode, or the same
/// query, reopens on it, and anything else starts blank (issue 0096).
struct NewBookDrafts: Equatable, Sendable {
    private var drafts: [NewBookOrigin: NewBookDraft] = [:]

    /// What the form opens on: the draft left from a previous attempt, or a blank one.
    func draft(for origin: NewBookOrigin) -> NewBookDraft {
        drafts[origin] ?? origin.blankDraft
    }

    /// Keeps what was typed. Called as the form goes, whatever took it away.
    mutating func remember(
        _ draft: NewBookDraft,
        for origin: NewBookOrigin
    ) {
        drafts[origin] = draft
    }

    /// Forgets a draft that has become a book. Nothing else clears one: a session's worth of
    /// abandoned drafts is a few hundred bytes, and losing one is worse than keeping it.
    mutating func forget(_ origin: NewBookOrigin) {
        drafts[origin] = nil
    }
}
