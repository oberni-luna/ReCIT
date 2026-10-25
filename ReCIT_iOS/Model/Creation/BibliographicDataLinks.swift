//
//  BibliographicDataLinks.swift
//  ReCIT_iOS
//
//  Where to read more about inventaire.io's bibliographic data, from the help the book creation
//  opens: the same three places inventaire.io's own notice points to
//  (`bibliographic_data_settings.svelte`, inventaire-client) — its wiki page about entities,
//  the project's chat room about them, and the reader's own contributions.
//
//  See PRD 0026.
//

import Foundation

enum BibliographicDataLinks {

    /// The wiki page about entities and where their data comes from.
    static let wiki: URL? = .init(string: "https://wiki.inventaire.io/wiki/Entities_data")

    /// The project's Matrix room about bibliographic data.
    static let chat: URL? = .init(string: "https://app.element.io/#/room/#inventaire_entities:matrix.org")

    /// The reader's contributions to inventaire.io's own database, on the website.
    static func contributions(username: String, baseUrl: String) -> URL? {
        var components: URLComponents? = .init(string: baseUrl)
        components?.path = "/users/\(username)/contributions"
        return components?.url
    }
}
