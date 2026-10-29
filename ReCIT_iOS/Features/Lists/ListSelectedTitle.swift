//
//  ListSelectedTitle.swift
//  ReCIT_iOS
//
//  The selected element's title, centred under the cover flow, and under it its authors — or,
//  for an author, what inventaire.io says they are. See PRD 0029.
//

import SwiftData
import SwiftUI

struct ListSelectedTitle: View {
    let uri: String
    let listType: EntityListType

    @Query private var works: [Work]
    @Query private var authors: [Author]

    init(uri: String, listType: EntityListType) {
        self.uri = uri
        self.listType = listType
        _works = Query(filter: #Predicate<Work> { $0.uri == uri })
        _authors = Query(filter: #Predicate<Author> { $0.uri == uri })
    }

    private var title: String {
        listType == .author ? authors.first?.name ?? "" : works.first?.title ?? ""
    }

    private var byline: String? {
        guard listType != .author else { return authors.first?.subtitle }
        guard let work = works.first else { return nil }

        let names: [String] = work.authors.map(\.name).filter { $0.isEmpty == false }
        return names.isEmpty ? work.subtitle : names.joined(separator: ", ")
    }

    var body: some View {
        VStack(spacing: .xxSmall) {
            Text(title)
                .textStyle(.content400Bold)
                .foregroundStyle(.foregroundDefault)

            if let byline, byline.isEmpty == false {
                Text(byline)
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundSecondary)
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }
}
