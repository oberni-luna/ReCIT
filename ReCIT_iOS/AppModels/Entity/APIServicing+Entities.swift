//
//  APIServicing+Entities.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 11/11/2026.
//

import Foundation

nonisolated extension APIServicing {
    /// The entities under `uris`, fifty to a request, named in the phone's language.
    ///
    /// Read by `EntitySync`, off the main actor. `EntityModel.fetchEntities` asks the same of
    /// the server for the screens, and can also ask it to create an edition (`autocreate`).
    func entities(uris: [String]) async throws -> [EntityResultDTO] {
        var entities: [EntityResultDTO] = []
        for batch in uris.splitInSubArrays(of: 50) {
            let endpoint: String = "/api/entities/by-uris?uris=\(batch.joined(separator: "|"))&attributes=info|labels|descriptions|claims|image&lang=\(ContentLanguage.preferred)"
            let answer: EntityResultsDTO? = try await fetchData(fromEndpoint: endpoint)
            entities.append(contentsOf: answer.map { Array($0.entities.values) } ?? [])
        }
        return entities
    }
}
