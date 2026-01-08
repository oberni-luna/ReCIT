//
//  EditionModel.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 12/12/2025.
//

import Foundation
import Combine
import SwiftData

class EntityModel: ObservableObject {
    private let apiService: APIService
    
    init(fetchDataService: APIService = .init(env: .production)) {
        self.apiService = fetchDataService
    }

    func getEdition(modelContext: ModelContext, uri: String) throws -> Edition? {
        let predicate = #Predicate<Edition> { object in
            object.uri == uri
        }
        let descriptor = FetchDescriptor(predicate: predicate)
        return try modelContext.fetch(descriptor).first
    }
}
