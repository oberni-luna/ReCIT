//
//  InventoryModel.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 30/11/2025.
//
import SwiftData
import Foundation
import Combine

class InventoryModel: ObservableObject {

    private let fetchDataService: APIService
    @Published var myUser: User?

    init(fetchDataService: APIService = .init(env: .production)) {
        self.fetchDataService = fetchDataService
    }

    func syncItems(forUser: User, modelContext: ModelContext) async throws {
        let itemsDTO: ItemsDTO? = try await fetchDataService.fetchData(fromEndpoint: "/api/items?action=by-users&users=\(forUser._id)")
        if let itemsDTO {
            for itemDTO in itemsDTO.items {
                let myItem = InventoryItem(itemDTO: itemDTO, baseUrl: fetchDataService.baseUrl())

                var predicate = #Predicate<InventoryItem> { object in
                    object._id == itemDTO._id
                }
                var descriptor = FetchDescriptor(predicate: predicate)
                if let existingItem = try? modelContext.fetch(descriptor).first {
                    modelContext.delete(existingItem)
                }
                modelContext.insert(myItem)
            }
            try modelContext.save()
        } else {
            throw NetworkError.badResponse
        }
    }

}
