//
//  EntityListDetail.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 30/11/2025.
//

import SwiftUI

struct EntityListDetail: View {
    @EnvironmentObject private var inventoryModel: InventoryModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    enum ViewState {
        case loadingItems(list: EntityList)
        case loaded(items: [any Entity])
        case error(error: Error)
        case empty
    }

    @State var state: ViewState
    @Binding var path: NavigationPath

    var body: some View {
        switch state {
        case .empty:
            Text("This list is empty")
        case .error(error: let error):
            Text("Error loading list \(error.localizedDescription).")
        case .loadingItems:
            Text("Loading items...")
                .onAppear {
                    Task {
                        await fetchItemEntities()
                    }
                }
        case .loaded(items: let items):
            List {
                ForEach(items, id: \.uri) { item in
                    Button {
                        if let entityDestination = item.entityDestination {
                            path.append(entityDestination)
                        }
                    } label : {
                        EntityCellView(entity: item)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @MainActor
    private func fetchItemEntities() async {
        do {
            switch state {
            case .loadingItems(list: let list):
                if let items: [any Entity] = switch list.type {
                case .author:
                    try await inventoryModel.getOrFetchAuthors(modelContext: modelContext, uris: list.elements.map(\.uri))
                case .work:
                    try await inventoryModel.getOrFetchWorks(modelContext: modelContext, uris: list.elements.map(\.uri))
                case .publisher:
                    []
                } {
                    self.state = .loaded(items: items)
                } else {
                    self.state = .empty
                }
            default:
                print(self.state)
            }
        } catch(let error) {
            self.state = .error(error: error)
        }
    }
}

private extension Entity {
    var entityDestination: EntityDestination? {
        switch self {
        case is Author:
            return .author(uri: self.uri)
        case is Work:
            return .work(uri: self.uri)
        default:
            return nil
        }
    }
}

#Preview {
//    EntityListDetail()
}
