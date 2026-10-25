//
//  EntityLabelUpdate.swift
//  ReCIT_iOS
//
//  A work renamed from « Modifier l'œuvre », as `PUT /api/entities/update-label` takes it: the
//  entity, the language of the label, and its new value. A work's title is a label, not a claim
//  — unlike an edition's, which is `wdt:P1476`.
//

import Foundation

struct EntityLabelUpdate: Codable, Equatable, Sendable {
    let uri: String
    let lang: String
    let value: String
}
