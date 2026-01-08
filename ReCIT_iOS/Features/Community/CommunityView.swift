//
//  CommunityView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 05/12/2025.
//

import SwiftUI
import SwiftData

struct CommunityView: View {
    @Query(sort: \Edition.title) var allItems: [Edition]

    @State private var searchText: String = ""
    @State private var path: NavigationPath = .init()

    var filteredItems: [Edition] {
        if searchText.isEmpty {
            return allItems
        } else {
            let filteredItems = allItems.compactMap { edition in
                let titleContainsQuery = edition.title.range(of: searchText, options: .caseInsensitive) != nil
                return titleContainsQuery ? edition : nil
            }
            return filteredItems
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredItems) { edition in
                    NavigationLink(value: edition) {
                        HStack(alignment: .top, spacing: 8) {
                            CellThumbnail(imageUrl: edition.image)

                            VStack(alignment: .leading) {
                                Text(edition.title)
                                    .font(.headline)
                            }
                        }
                    }
                }
            }
            .navigationDestination(for: Edition.self) { edition in
                EditionView(edition: edition)
            }
            .navigationTitle("👫 In the community")
            .listStyle(.plain)
            .searchable(text: $searchText)
        }
    }
}
