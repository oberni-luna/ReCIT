//
//  ListElementReader.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 16/11/2026.
//

import SwiftData
import SwiftUI

/// Reads from the store the work or the author `uri` names, as the list's type says, and hands
/// it to `content` — `nil` until the store holds it.
struct ListElementReader<Content: View>: View {
    private let listType: EntityListType
    private let content: (ListElementEntity?) -> Content

    @Query private var works: [Work]
    @Query private var authors: [Author]

    init(
        uri: String,
        listType: EntityListType,
        @ViewBuilder content: @escaping (ListElementEntity?) -> Content
    ) {
        self.listType = listType
        self.content = content
        _works = Query(filter: #Predicate<Work> { $0.uri == uri })
        _authors = Query(filter: #Predicate<Author> { $0.uri == uri })
    }

    private var entity: ListElementEntity? {
        listType == .author ? authors.first.map(ListElementEntity.author) : works.first.map(ListElementEntity.work)
    }

    var body: some View {
        content(entity)
    }
}

#Preview {
    ListElementReader(uri: "wd:Q25338", listType: .work) { entity in
        Text(entity?.title ?? "")
    }
    .modelContainer(for: [Work.self, Author.self], inMemory: true)
}
