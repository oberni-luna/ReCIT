//
//  EntitySaveFailure.swift
//  ReCIT_iOS
//
//  A change to a work or a person that did not land in full: what went wrong, and the edit as
//  far as it got. The form takes the edit back, so a retry sends only what is left.
//

import Foundation

struct EntitySaveFailure: Error {
    let edit: EntityEdit
    let underlying: Error
}
