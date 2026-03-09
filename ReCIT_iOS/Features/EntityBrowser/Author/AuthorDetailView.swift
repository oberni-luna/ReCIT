//
//  AuthorResultDetailView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 20/01/2026.
//

import SwiftUI

struct AuthorDetailView: View {
    @EnvironmentObject private var inventoryModel: InventoryModel
    @Environment(\.modelContext) private var modelContext
    
    enum ViewState {
        case loadingAuthor
        case loadingWorks(author: Author)
        case loaded(author: Author, works: [Work])
        case error(error: Error)
    }

    @State private var state: ViewState = .loadingAuthor

    let authorUri: String
    @Binding var path: NavigationPath

    var body: some View {
        switch state {
        case .loadingAuthor:
            Text("author.loading")
                .onAppear {
                    Task {
                        await fetchAuthor()
                    }
                }
        case .loadingWorks(author: let author):
            Text("author.loading_works \(author.name)")
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
                            .textStyle(.content400Bold)
                            .foregroundStyle(.foregroundDefault)
                        if let subtitle = author.subtitle {
                            Text(subtitle)
                                .textStyle(.content300)
                                .foregroundStyle(.foregroundDefault)
                        }
                        if let dob = author.dateOfBirth {
                            Text("author.birth_date \(dob.formatted(date:.long, time:.omitted))")
                                .textStyle(.content300)
                                .foregroundStyle(.foregroundDefault)
                        }
                    }
                }

                Section {
                    ForEach(works) { work in
                        if !work.title.isEmpty {
                            let result:SearchResult = SearchResult(id: work.uri, uri: work.uri, title: work.title, description: work.subtitle, imageUrl: work.image, score: 0, type: .works)
                            Button {
                                path.append(NavigationDestination.work(uri: work.uri))
                            } label: {
                                NavigationLink(value: UUID()) {
                                    SearchResultCell(result: result)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } header: {
                    Text("author.works.header \(author.name)")
                        .textStyle(.action200)
                        .foregroundStyle(.foregroundSecondary)
                }
            }
            .applyListBackground()
            .navigationTitle("nav.author")
        case .error(error: let error):
            Text("error.with_message \(error.localizedDescription)")
        }
    }

    @MainActor
    private func fetchAuthor() async {
        do {
            if let author = try await inventoryModel.getOrFetchAuthors(modelContext: modelContext, uris: [authorUri])?.first {
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
