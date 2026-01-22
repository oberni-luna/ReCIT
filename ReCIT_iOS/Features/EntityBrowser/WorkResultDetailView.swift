//
//  WorkResultDetailView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 20/01/2026.
//

import SwiftUI

struct WorkResultDetailView: View {
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

    let workUri: String
    @Binding var path: NavigationPath

    var body: some View {
        switch state {
        case .loadingWork:
            Text("Loading work...")
                .onAppear {
                    Task {
                        await fetchWork()
                    }
                }
        case .loadingEditions(work: let work):
            Text("Loading editions for \(work.title)")
                .onAppear {
                    Task {
                        await fetchEditions()
                    }
                }
        case .loaded(work: let work, editions: let editions):
            List {
                Section {
                    VStack(alignment: .leading, spacing: .small) {
                        if let image = work.image {
                            CellThumbnail(imageUrl: image, cornerRadius: .minimal, size: 72)
                        }
                        Text(work.title)
                            .font(.headline)
                        if let subtitle = work.subtitle {
                            Text(subtitle)
                                .font(.subheadline)
                        }
                    }
                }

                Section {
                    ForEach(editions) { edition in
                        let result:SearchResult = SearchResult(id: edition.uri, uri: edition.uri, title: edition.title, description: edition.subtitle, imageUrl: edition.image, score: 0, type: .works)
                        Button {
                            path.append(edition)
                        } label: {
                            SearchResultCell(result: result)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Editions de \(work.title)")
                }
            }
        case .error(error: let error):
            Text("Error \(error.localizedDescription) !!")
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
