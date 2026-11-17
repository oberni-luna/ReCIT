//
//  SearchAddEditionRow.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 16/11/2026.
//

import SwiftUI

/// The row that closes inventaire.io's answer in Recherche, results or none. Opens « Nouveau
/// livre » on the query.
struct SearchAddEditionRow: View {
    private let query: String

    @Environment(\.openNewBook) private var openNewBook: OpenNewBookAction

    init(_ query: String) {
        self.query = query
    }

    var body: some View {
        Button("inventory.search.results.add_edition") {
            openNewBook(.search(query: query))
        }
        .textStyle(.action300)
        .foregroundStyle(.foregroundTinted)
        .accessibilityIdentifier(AccessibilityID.row)
    }
}

private extension SearchAddEditionRow {
    enum AccessibilityID {
        static let row: String = "e2e.searchAddEdition"
    }
}

#Preview {
    List {
        Section {
            SearchAddEditionRow("monte cristo")
        }
    }
    .listStyle(.insetGrouped)
}
