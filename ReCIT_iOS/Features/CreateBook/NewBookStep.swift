//
//  NewBookStep.swift
//  ReCIT_iOS
//
//  The screens pushed over the work search, in the sheet's own navigation stack.
//
//  The root is always the search — « de quel livre s'agit-il ? » — and what is pushed on it
//  follows from the answer: a work picked, or one to create, and on the way to creating it the
//  work inventaire.io recognised after all.
//
//  See PRD 0026.
//

import Foundation

enum NewBookStep: Hashable {
    /// « Nouvelle édition » — the edition's form, every property of it.
    case edition

    /// « Nouvelle œuvre » — the work being described, its title and authors.
    case newWork

    /// « Œuvre déjà connue » — the reconnaissance pass found the work being created.
    case recognisedWork(uri: String)

    /// « Image depuis une URL » — a cover found on the web.
    case coverFromURL

    /// One of the screens of the catalogue's properties.
    case property(EditionPropertyStep)

    /// Where a draft left from an earlier attempt reopens: on the screen it was being written
    /// in, rather than on a search the reader has already answered.
    static func resuming(_ draft: NewBookDraft) -> [NewBookStep] {
        draft.hasWork ? [.edition] : []
    }
}
