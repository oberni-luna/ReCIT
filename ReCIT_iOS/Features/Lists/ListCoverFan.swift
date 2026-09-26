//
//  ListCoverFan.swift
//  ReCIT_iOS
//
//  The first covers of a list, fanned out at the head of its row: portraits of books for a
//  list of works, round portraits of people for a list of authors. The first element sits in
//  front. Always as wide as a full fan, so the names beside it line up from row to row; an
//  empty list shows one grey slot rather than nothing.
//
//  Reads the entities from SwiftData and only asks `EntityModel` to fetch the ones the store
//  does not hold yet — the covers appear as they arrive (ADR 0001).
//

import SwiftUI
import SwiftData

struct ListCoverFan: View {
    @Environment(EntityModel.self) private var entityModel
    @Environment(\.modelContext) private var modelContext

    let uris: [String]
    let type: EntityListType

    @Query private var works: [Work]
    @Query private var authors: [Author]

    /// How far each cover sits to the right of the one in front of it.
    private static let step: CGFloat = 13
    private static let size: ThumbnailSize = .small

    init(
        uris: [String],
        type: EntityListType
    ) {
        self.uris = uris
        self.type = type
        _works = Query(filter: #Predicate<Work> { uris.contains($0.uri) })
        _authors = Query(filter: #Predicate<Author> { uris.contains($0.uri) })
    }

    private var images: [String?] {
        guard !uris.isEmpty else { return [nil] }

        let known: [String: String?] = switch type {
        case .author:
            Dictionary(authors.map { ($0.uri, $0.image) }, uniquingKeysWith: { first, _ in first })
        case .work, .publisher:
            Dictionary(works.map { ($0.uri, $0.image) }, uniquingKeysWith: { first, _ in first })
        }
        return uris.map { known[$0] ?? nil }
    }

    private var fanWidth: CGFloat {
        Self.size.sizeInPt + Self.step * CGFloat(ListCoverPreview.limit - 1)
    }

    var body: some View {
        ZStack(alignment: .leading) {
            ForEach(images.enumerated(), id: \.offset) { index, image in
                thumbnail(image)
                    .offset(x: Self.step * CGFloat(index))
                    .zIndex(Double(-index))
            }
        }
        .frame(width: fanWidth, alignment: .leading)
        .accessibilityHidden(true)
        .task(id: uris) {
            await fetchMissing()
        }
    }

    @ViewBuilder
    private func thumbnail(_ image: String?) -> some View {
        switch type {
        case .author:
            CellThumbnail(
                imageUrl: image,
                cornerRadius: .full,
                size: Self.size
            )
        case .work, .publisher:
            CellThumbnail(
                imageUrl: image,
                cornerRadius: .minimal,
                size: Self.size,
                shape: .portrait
            )
        }
    }

    private func fetchMissing() async {
        switch type {
        case .author:
            _ = try? await entityModel.getOrFetchAuthors(
                modelContext: modelContext,
                uris: uris
            )
        case .work:
            _ = try? await entityModel.getOrFetchWorks(
                modelContext: modelContext,
                uris: uris
            )
        case .publisher:
            break
        }
    }
}
