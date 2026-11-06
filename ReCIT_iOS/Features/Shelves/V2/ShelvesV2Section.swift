//
//  ShelvesV2Section.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 06/11/2026.
//
//  « Étagères (v2) », in the Inventaire between the carousel and « Tous les livres »: one row per
//  étagère of mine, its name and how many books it holds, opening its v2 screen
//  (`ShelfDetailV2View`). Here so the two screens can be tried side by side; it goes when one
//  of them does.
//

import SwiftData
import SwiftUI

struct ShelvesV2Section: View {
    let shelves: [Shelf]
    @Binding var path: NavigationPath

    var body: some View {
        VStack(alignment: .leading, spacing: .zero) {
            ShelfSectionHeader(title: String(localized: "shelves.v2.header"))

            LazyVStack(alignment: .leading, spacing: .zero) {
                ForEach(shelves) { shelf in
                    Button {
                        path.append(NavigationDestination.shelf(id: shelf._id, layout: .tabs))
                    } label: {
                        ShelvesV2Row(shelf)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier(AccessibilityID.row)

                    Divider()
                        .padding(.leading, .medium)
                }
            }
        }
    }
}

private extension ShelvesV2Section {
    enum AccessibilityID {
        static let row: String = "e2e.shelvesV2.row"
    }
}

#Preview(traits: .modifier(ShelfPreviewStore())) {
    @Previewable @State var path: NavigationPath = .init()
    @Previewable @Query var shelves: [Shelf]
    ShelvesV2Section(shelves: shelves, path: $path)
}
