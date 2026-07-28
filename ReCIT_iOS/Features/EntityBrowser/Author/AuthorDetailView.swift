//
//  AuthorResultDetailView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 20/01/2026.
//

import SwiftUI
import SwiftData

struct AuthorDetailView: View {
    @Environment(EntityModel.self) private var entityModel
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
        content
            .task {
                await load()
            }
    }

    @ViewBuilder
    var content: some View {
        switch state {
        case .loadingAuthor:
            Text("author.loading")
        case .loadingWorks(author: let author):
            Text("author.loading_works \(author.name)")
        case .loaded(author: let author, works: let works):
            List {
                Section {
                    VStack(alignment: .leading, spacing: .small) {
                        if let image = author.image {
                            CellThumbnail(imageUrl: image, cornerRadius: .full, size: .large)
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

    /// Shows cached data immediately (if any), then revalidates the author and
    /// their works in the background, updating the cache in place. When a cached
    /// copy is already on screen, network failures are swallowed so the
    /// stale-but-useful data keeps showing.
    @MainActor
    private func load() async {
        let cached: Author? = entityModel.localAuthor(modelContext: modelContext, uri: authorUri)
        if let cached {
            state = cached.works.isEmpty
                ? .loadingWorks(author: cached)
                : .loaded(author: cached, works: cached.works)
        }

        do {
            guard let author = try await entityModel.refreshAuthor(modelContext: modelContext, uri: authorUri) else {
                if cached == nil {
                    state = .error(error: NSError(domain: "No author", code: 0, userInfo: nil))
                }
                return
            }

            if cached == nil {
                state = .loadingWorks(author: author)
            }

            let works: [Work] = try await entityModel.getAuthorWorks(modelContext: modelContext, author: author) ?? author.works
            state = .loaded(author: author, works: works)
        } catch(let error) {
            if cached == nil {
                state = .error(error: error)
            }
        }
    }
}

#Preview {
//    AuthorResultDetailView()
}
