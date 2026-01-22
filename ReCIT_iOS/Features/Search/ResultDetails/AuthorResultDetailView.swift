//
//  AuthorResultDetailView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 20/01/2026.
//

import SwiftUI

struct AuthorResultDetailView: View {
    @EnvironmentObject private var inventoryModel: InventoryModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    enum ViewState {
        case loadingAuthor
        case loadingWorks(author: Author)
        case loaded(author: Author, works: [Work])
        case error(error: Error)
    }

    @State private var state: ViewState = .loadingAuthor

    let result: SearchResult
    @Binding var path: NavigationPath

    var body: some View {
        switch state {
        case .loadingAuthor:
            Text("Loading author...")
                .onAppear {
                    Task {
                        await fetchAuthor()
                    }
                }
        case .loadingWorks(author: let author):
            Text("Loading works for \(author.name)")
                .onAppear {
                    Task {
                        await fetchWorks()
                    }
                }
        case .loaded(author: let author, works: let works):
            List {
                Section {
                    VStack(alignment: .leading, spacing: .small) {
                        if let image = author.image {
                            CellThumbnail(imageUrl: image, cornerRadius: .full, size: 72)
                        }
                        Text(author.name)
                            .font(.headline)
                        if let subtitle = author.subtitle {
                            Text(subtitle)
                                .font(.subheadline)
                        }
                        if let dob = author.dateOfBirth {
                            Text("Né le \(dob.formatted(date:.long, time:.omitted))")
                                .font(.subheadline)
                        }
                    }
                }

                Section {
                    ForEach(works) { work in
                        if !work.title.isEmpty {
                            let result:SearchResult = SearchResult(id: work.uri, uri: work.uri, title: work.title, description: work.subtitle, imageUrl: work.image, score: 0, type: .works)
                            Button {
                                path.append(result)
                            } label: {
                                SearchResultCell(result: result)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } header: {
                    Text("Oeuvres de \(author.name)")
                }
            }
        case .error(error: let error):
            Text("Error \(error.localizedDescription) !!")
        }
    }

    @MainActor
    private func fetchAuthor() async {
        do {
            if let author = try await inventoryModel.getOrFetchAuthor(modelContext: modelContext, uri: result.uri) {
                self.state = .loadingWorks(author: author)
            } else {
                self.state = .error(error: NSError(domain: "No author", code: 0, userInfo: nil))
            }
        } catch(let error) {
            self.state = .error(error: error)
        }
    }

    @MainActor
    private func fetchWorks() async {
        do {
            switch state {
            case .loadingWorks(let author):
                if let works = try await inventoryModel.getAuthorWorks(modelContext: modelContext, author: author) {
                    self.state = .loaded(author: author, works: works)
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
//    AuthorResultDetailView()
}
