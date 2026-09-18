//
//  IsbnFactsDTO.swift
//  ReCIT_iOS
//
//  What `GET /api/data/isbn` answers. A public endpoint — no session, no account — that
//  decomposes an ISBN: its registration group, the language of that group, and whether the
//  check digit adds up.
//
//  Only two fields are read. The rest of the answer is the ISBN taken apart in every notation,
//  and the app has no use for it.
//
//  See PRD 0015.
//

import Foundation

struct IsbnFactsDTO: Codable, Equatable, Sendable {

    /// The language code of the registration group — `fr` for the `978-2` group.
    let groupLang: String?

    /// The same language as a wikidata entity — `wd:Q150`.
    let groupLangUri: String?

    let isValid: Bool?
}
