//
//  EditionPagesLoader.swift
//  ReCIT_iOS
//
//  Fetches an edition's page count (Wikidata P1104) from the public inventaire
//  entities API, used to size a painted spine's thickness. Read-only, unauthenticated
//  (entity reads need no session). See ADR 0003.
//

import Foundation

actor EditionPagesLoader {
    static let shared: EditionPagesLoader = .init()

    /// Returns the number of pages for an edition URI, or `nil` when the entity has no
    /// P1104 claim (or the request fails).
    func numberOfPages(forEditionUri uri: String) async -> Int? {
        var components: URLComponents? = .init(string: "\(Env.production.apiBaseUrl)/api/entities/by-uris")
        components?.queryItems = [
            .init(name: "uris", value: uri),
            .init(name: "attributes", value: "claims"),
            .init(name: "lang", value: "fr")
        ]
        // `attributes=claims` returns a lean shape (`uri`, `_rev`, `claims` only), so a
        // dedicated DTO is decoded instead of the full EntityResultDTO. The entity is
        // keyed by its canonical `inv:` uri (which differs from an `isbn:` request), so
        // the single returned entity is taken rather than indexed by the requested uri.
        guard let url = components?.url,
              let (data, _) = try? await URLSession.shared.data(from: url),
              let result = try? JSONDecoder().decode(PagesEntitiesDTO.self, from: data),
              let entity = result.entities.values.first,
              let claim = entity.claims[WikidataProperty.numberOfPages.rawValue]?.first
        else {
            return nil
        }
        if let number = claim.getNumberValue() { return Int(number) }
        if let string = claim.getStringValue() { return Int(string) }
        return nil
    }
}

private struct PagesEntitiesDTO: Codable {
    let entities: [String: PagesEntityDTO]
}

private struct PagesEntityDTO: Codable {
    let claims: [String: [ClaimValue]]
}
