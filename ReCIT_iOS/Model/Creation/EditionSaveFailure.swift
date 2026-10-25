//
//  EditionSaveFailure.swift
//  ReCIT_iOS
//
//  A change to an edition that did not land in full: what went wrong, and the edit as far as it
//  got. The form takes the edit back so a retry sends only what is left, and the book screen
//  shows what the server already holds.
//

import Foundation

struct EditionSaveFailure: Error {
    let edit: EditionEdit
    let underlying: Error
}
