//
//  RelationActionPayload.swift
//  ReCIT_iOS
//
//  The whole body of every relation write.
//
//  `POST /api/relations/request` · `/accept` · `/discard` · `/cancel` · `/unfriend` each take
//  one parameter, `user`, and nothing else — checked against inventaire.io's live
//  `api_specs.json` on 2026-09-12. This is why the request sheet carries no message: there is
//  no field on the server to put one in.
//

import Foundation

struct RelationActionPayload: Codable {
    let user: String
}
