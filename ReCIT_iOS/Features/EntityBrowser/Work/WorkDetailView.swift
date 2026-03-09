//
//  WorkResultDetailView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 20/01/2026.
//

import SwiftUI
import SwiftData

struct WorkDetailView: View {
    @EnvironmentObject private var inventoryModel: InventoryModel
    @EnvironmentObject var listModel: ListModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    enum ViewState {
        case loadingWork
        case loadingEditions(work: Work)
        case loaded(work: Work, editions: [Edition])
        case error(error: Error)
    }

    @State private var viewState: ViewState = .loadingWork
    @State private var nextEntityDestination: NavigationDestination?
    @State private var showAddToListDialog: Bool = false
    @State private var addToListItemForm: EntityList? = nil

    let workUri: String
    @Binding var path: NavigationPath

    var body: some View {
        List {
            switch viewState {
            case .loadingWork:
                ProgressView()
            case .loadingEditions(work: let work):
                headerSection(work: work)
            case .loaded(work: let work, editions: let editions):
                headerSection(work: work)
                editionsSection(work: work, editions: editions)
                    .selectListToAdd(
                        showAddToListDialog: $showAddToListDialog,
                        onListSelected: { list in
                            addToListItemForm = list
                        }
                    )
            case .error(error: let error):
                Text("error.with_message \(error.localizedDescription)")
            }
        }
        .onAppear {
            Task {
                await fetchWork()
                await fetchEditions()
            }
        }
        .onChange(of: nextEntityDestination) { _, destination in
            if let destination {
                path.append(destination)
                nextEntityDestination = nil
            }
        }
        .sheet(item: $addToListItemForm) { list in
            switch viewState {
            case .loaded(let work, _ ):
                ListItemFormView(entity: work, list: list)
            default:
                EmptyView()
            }
        }
        .listStyle(.insetGrouped)
        .applyListBackground()
        .navigationTitle("nav.work")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            toolbarContent
        }
    }

    @ToolbarContentBuilder
    var toolbarContent : some ToolbarContent {
        ToolbarItemGroup(placement: .confirmationAction) {
            Button {
                showAddToListDialog = true
            } label: {
                Label("action.add_to_list", systemImage: "list.bullet")
            }
        } label: {
            Image(systemName: "ellipsis")
                .imageScale(.large)
        }
    }

    @ViewBuilder
    func headerSection(work: Work) -> some View {
        Section {
            EntitySummaryView(entityUri: work.uri)

            EntityAuthorsView(
                authors: work.authors.sorted(by: { $0.name < $1.name }),
                entityDestination: $nextEntityDestination
            )
        } header: {
            EntityHeaderView(
                title: work.title,
                subtitle: work.subtitle,
                imageUrl: work.image
            )
        }
    }

    @ViewBuilder
    func editionsSection(work: Work, editions: [Edition]) -> some View {
        Section {
            ForEach(editions) { edition in
                let result:SearchResult = SearchResult(id: edition.uri, uri: edition.uri, title: edition.title, description: edition.subtitle, imageUrl: edition.image, score: 0, type: .works)
                Button {
                    path.append(NavigationDestination.edition(uri: edition.uri))
                } label: {
                    NavigationLink(value: UUID()) {
                        SearchResultCell(result: result)
                    }
                }
                .buttonStyle(.plain)
            }
        } header: {
            Text("work.editions.header \(work.title)")
                .textStyle(.action200)
                .foregroundStyle(.foregroundSecondary)
        }
    }

    @MainActor
    private func fetchWork() async {
        do {
            if let work = try await inventoryModel.getOrFetchWork(modelContext: modelContext, uri: workUri) {
                self.viewState = .loadingEditions(work: work)
            } else {
                self.viewState = .error(error: NSError(domain: "No work", code: 0, userInfo: nil))
            }
        } catch(let error) {
            self.viewState = .error(error: error)
        }
    }

    @MainActor
    private func fetchEditions() async {
        do {
            switch viewState {
            case .loadingEditions(work: let work):
                if let editions = try await inventoryModel.getWorkEditions(modelContext: modelContext, work: work) {
                    self.viewState = .loaded(work: work, editions: editions)
                } else {
                    self.viewState = .error(error: NSError(domain: "No works", code: 0, userInfo: nil))
                }
            default:
                print(self.viewState)
            }
        } catch(let error) {
            self.viewState = .error(error: error)
        }
    }
}

