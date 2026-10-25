//
//  EditionEditStep.swift
//  ReCIT_iOS
//
//  One request of a save, as `EditionEdit.nextStep` lists them: what has to exist before the
//  claims can name it — a picture, an author, a work — then the claims, one at a time.
//

import Foundation

enum EditionEditStep: Equatable, Sendable {
    /// Upload a new cover, for the hash `invp:P2` takes.
    case uploadCover(Data)
    /// Create an author inventaire.io does not have, labelled with its name.
    case createAuthor(id: UUID, label: String, language: String)
    /// Create the work the edition is an edition of, with its authors.
    case createWork(label: String, language: String, authorUris: [String])
    /// Create a publisher, a collection or a person the edition names, labelled with the name
    /// the reader typed.
    case createEntity(id: UUID, label: String, language: String, kind: EntityCreationKind)
    /// Change one claim.
    case claim(EditionClaimUpdate)
}
