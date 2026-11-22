//
//  BookAbsentCopySection.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 22/11/2026.
//

import SwiftUI

/// « Dans mon inventaire » on a book I own no copy of: what adding it is for, and the pill that
/// adds it — the « … » menu's own action. Once the copy is in the store, Mon exemplaire shows it
/// in its place.
struct BookAbsentCopySection: View {
    private let edition: Edition

    init(_ edition: Edition) {
        self.edition = edition
    }

    var body: some View {
        Section("edition.my_inventory") {
            VStack(alignment: .leading, spacing: .medium) {
                Text("book.my_copy.absent")
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundSecondary)

                AddToInventoryButton(edition: edition) {
                    Label("book.my_copy.add_to_inventory", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.pill(.prominent))
                .accessibilityIdentifier(AccessibilityID.addToInventory)
            }
            .padding(.vertical, .small)
        }
    }
}

private extension BookAbsentCopySection {
    enum AccessibilityID {
        static let addToInventory: String = "e2e.book.myCopy.addToInventory"
    }
}

#Preview {
    List {
        BookAbsentCopySection(
            .init(uri: "isbn:9782070360024", title: "L'Étranger", lang: "fr", authorNames: [])
        )
    }
}
