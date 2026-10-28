//
//  GravatarDTO.swift
//  ReCIT_iOS
//
//  What `GET /api/images/gravatar` answers: the Gravatar address of the account's e-mail, built by
//  the server so the address itself never has to leave it. The url answers `404` when the address
//  has no Gravatar (`?d=404`).
//

import Foundation

struct GravatarDTO: Codable {
    let url: String
}
