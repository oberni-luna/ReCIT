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

    private let apiService: APIService
    @Published var myUser: User?

    init(fetchDataService: APIService = .init(env: .production)) {
        self.apiService = fetchDataService
    }

    func syncItems(forUser: User, modelContext: ModelContext) async throws {
        let itemsDTO: ItemsDTO? = try await apiService.fetchData(fromEndpoint: "/api/items?action=by-users&users=\(forUser._id)")
        if let itemsDTO {
            for itemDTO in itemsDTO.items {
                let myItem = InventoryItem(itemDTO: itemDTO, baseUrl: apiService.baseUrl())

                let predicate = #Predicate<InventoryItem> { object in
                    object._id == itemDTO._id
                }
                let descriptor = FetchDescriptor(predicate: predicate)
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
