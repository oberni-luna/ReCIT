//
//  EntityListDetail.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 30/11/2025.
//

import SwiftUI

struct EntityListDetail: View {
    @EnvironmentObject private var listModel: ListModel
    @EnvironmentObject private var entityModel: EntityModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    enum ViewState {
        case loadingItems
        case loaded(items: [EntityListItem : any Entity])
        case error(error: Error)
        case empty
    }

    @State var list: EntityList
    @Binding var path: NavigationPath

    @State var state: ViewState = .loadingItems
    @State private var presentEditForm: Bool = false

    @ViewBuilder
    var body: some View {
        List {
            Section {
                itemView
            }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("action.edit", systemImage: "pencil") {
                    presentEditForm = true
                }
            }
        }
        .sheet(isPresented: $presentEditForm) {
            ListFormView(list: list)
        }
        .applyListBackground()
    }

    @ViewBuilder
    var itemView: some View {
        switch state {
        case .empty:
            Text("list.empty")
                .textStyle(.content300)
        case .error(error: let error):
            Text("list.error.loading \(error.localizedDescription)")
                .textStyle(.content300)
        case .loadingItems:
            Text("list.loading")
                .onAppear {
                    Task {
                        await fetchItemEntities()
                    }
                }
        case .loaded(items: let items):
            ForEach(Array(items.keys), id: \._id) { key in
                if let item = items[key] {
                    Button {
                        if let entityDestination = item.entityDestination {
                            path.append(entityDestination)
                        }
                    } label : {
                        NavigationLink(value: UUID()) {
                            ListItemCellView(listItem: key, entity: item)
                        }
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing) {
                        Button("action.delete", systemImage: "trash") {
                            Task {
                                await deleteItem(listItem: key)
                            }
                        }
                    }
                }
            }
        }
    }

    @MainActor
    private func deleteItem(listItem: EntityListItem) async {
        do {
            try await listModel.deleteElementsInList(modelContext: modelContext, listId: list._id, elementIds: [listItem.uri])

            self.state = switch state {
            case .loaded(let items):
                    .loaded(items: items.filter { $0.key != listItem } )
            default: state
            }
        } catch {
            
        }
    }

    @MainActor
    private func fetchItemEntities() async {
        do {
            switch state {
            case .loadingItems:
                if let entities: [any Entity] = switch list.type {
                case .author:
                    try await entityModel.getOrFetchAuthors(modelContext: modelContext, uris: list.elements.map(\.uri))
                case .work:
                    try await entityModel.getOrFetchWorks(modelContext: modelContext, uris: list.elements.map(\.uri))
                case .publisher:
                    []
                } {
                    let items:[EntityListItem : any Entity] =
                    Dictionary(uniqueKeysWithValues: zip(list.elements, entities))

                    self.state = items.isEmpty ? .empty : .loaded(items: items)
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
    var entityDestination: NavigationDestination? {
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

