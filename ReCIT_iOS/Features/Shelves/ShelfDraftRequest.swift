//
//  ShelfDraftRequest.swift
//  ReCIT_iOS
//
//  What turns `ShelfFormView` from a write into an answer.
//
//  The sorting surface's « + » opens the very same form the carousel opens, but
//  confirming it must not touch the server: it hands a name back and the name becomes
//  a draft on the change stack, which is what makes "create it, fill it, then save"
//  one movement (PRD 0008). Handed as **one value rather than two optionals** so the
//  two modes cannot be half-set: a form holding this creates a draft, a form without
//  it writes, and there is no third state to reason about.
//
//  It carries the naming rule as well as the callback, because the refusal belongs to
//  the form — a duplicate has to be stopped while the user is still looking at the
//  field they typed it into, not after it has become a section holding books.
//

import Foundation

struct ShelfDraftRequest {

    /// Which names are already taken on the surface — existing étagères and drafts
    /// alike. Consulted as the user types, not on submit.
    let nameRule: SortDraftNameRule

    /// Handed the trimmed name when the form is confirmed. Nothing is written here or
    /// by the form; the caller decides what a name becomes.
    let onCreate: (String) -> Void
}
