//
//  MyInventoryView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 26/08/2025.
//

import SwiftUI
import SwiftData

struct WorkListView: View {
    @Query(sort: \Work.title) var allWorks: [Work]

    @State private var searchText: String = ""
    @State private var path: NavigationPath = .init()

    var filteredWorks: [Work] {
        if searchText.isEmpty {
            return allWorks
        } else {
            let filteredItems = allWorks.compactMap { work in
                let titleContainsQuery = work.title.range(of: searchText, options: .caseInsensitive) != nil

                return titleContainsQuery ? work : nil
            }
            return filteredItems
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredWorks) { work in
                    NavigationLink(value: work) {
                        HStack(alignment: .top, spacing: 8) {
                            CellThumbnail(imageUrl: work.image)

                            VStack(alignment: .leading) {
                                Text(work.title)
                                    .font(.headline)
                                Text(work.authors.map(\.name).joined(separator: ", "))
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
            .navigationDestination(for: Work.self) { work in

            }
            .navigationTitle("📋 Works")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("add", systemImage: "plus") {
//                        showNewListModal = true
                    }
                }
            }
            .listStyle(.plain)
            .searchable(text: $searchText)
        }
    }
}

#Preview {
//    MyInventoryView()
}
