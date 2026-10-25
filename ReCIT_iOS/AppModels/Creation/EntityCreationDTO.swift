//
//  EntityCreationDTO.swift
//  ReCIT_iOS
//
//  `POST /api/entities`, the request that creates one entity on inventaire.io — an author or a
//  work from « Modifier l'édition » — and the part of its answer the app reads: the uri the
//  entity was created under. The server answers the whole entity, under `entity`.
//

import Foundation

struct EntityCreationRequest: Codable {
    /// The label by language: one, in the edition's language.
    let labels: [String: String]
    let claims: [String: [String]]
}

struct CreatedEntityDTO: Codable {
    let entity: CreatedEntity

    struct CreatedEntity: Codable {
        let uri: String
    }
}
