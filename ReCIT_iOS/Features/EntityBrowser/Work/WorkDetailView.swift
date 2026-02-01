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
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    enum ViewState {
        case loadingWork
        case loadingEditions(work: Work)
        case loaded(work: Work, editions: [Edition])
        case error(error: Error)
    }

    @State private var state: ViewState = .loadingWork
    @State private var nextEntityDestination: EntityDestination?

    let workUri: String
    @Binding var path: NavigationPath

    var body: some View {
        List {
            switch state {
            case .loadingWork:
                ProgressView()
            case .loadingEditions(work: let work):
                headerSection(work: work)
            case .loaded(work: let work, editions: let editions):
                headerSection(work: work)
                editionsSection(work: work, editions: editions)
            case .error(error: let error):
                Text("Error \(error.localizedDescription) !!")
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
        .listStyle(.insetGrouped)
        .navigationTitle("Oeuvre")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    func headerSection(work: Work) -> some View {
        Section {
            EntitySummaryView(entityUri: work.uri)

            EntityAuthorsView(
                authors: work.authors,
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
                    path.append(EntityDestination.edition(uri: edition.uri))
                } label: {
                    SearchResultCell(result: result)
                }
                .buttonStyle(.plain)
            }
        } header: {
            Text("Editions de \(work.title)")
        }
    }

    @MainActor
    private func fetchWork() async {
        do {
            if let work = try await inventoryModel.getOrFetchWork(modelContext: modelContext, uri: workUri) {
                self.state = .loadingEditions(work: work)
            } else {
                self.state = .error(error: NSError(domain: "No work", code: 0, userInfo: nil))
            }
        } catch(let error) {
            self.state = .error(error: error)
        }
    }

    @MainActor
    private func fetchEditions() async {
        do {
            switch state {
            case .loadingEditions(work: let work):
                if let editions = try await inventoryModel.getWorkEditions(modelContext: modelContext, work: work) {
                    self.state = .loaded(work: work, editions: editions)
                } else {
                    self.state = .error(error: NSError(domain: "No works", code: 0, userInfo: nil))
                }
            default:
                print(self.state)
            }
        } catch(let error) {
            self.state = .error(error: error)
        }
    }

    

    
}
#Preview {
//    WorkResultDetailView()
}
