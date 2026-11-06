//
//  ShelfPresentationPage.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 06/11/2026.
//
//  An étagère's Présentation tab: its description, whole, in one card — then a card of what the
//  étagère is: who may see it, the day it was made and the day it last changed. A list's
//  Présentation (`ListPresentationPage`), less the type an étagère does not have. Editing stays
//  behind the navigation bar's pencil.
//

import SwiftData
import SwiftUI

struct ShelfPresentationPage: View {
    let shelf: Shelf

    /// The day the étagère last changed, once it has changed since it was made. An étagère
    /// freshly created from the app has no `updated` in the store, yet SwiftData read it back as
    /// the reference date (1 January 2001) on the simulator.
    private var lastChange: Date? {
        guard let updated = shelf.updated, updated > shelf.created else { return nil }
        return updated
    }

    var body: some View {
        if shelf.isStillInTheStore {
            if shelf.shelfDescription.isEmpty == false {
                Section {
                    Text(UserPresentationTab.linked(shelf.shelfDescription))
                        .textStyle(.content300)
                        .foregroundStyle(.foregroundDefault)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
            } else {
                Section {
                    EmptyStateView(
                        glyph: "text.quote",
                        title: "shelf.presentation.empty"
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, .large)
                }
                .listRowBackground(Color.clear)
            }

            Section {
                Text(FormVisibility(raw: shelf.visibility).label)
                    .infoRow(label: "shelf.info.visibility")

                Text(shelf.created, format: .dateTime.day().month(.wide).year())
                    .infoRow(label: "shelf.info.created")

                if let updated = lastChange {
                    Text(updated, format: .dateTime.day().month(.wide).year())
                        .infoRow(label: "shelf.info.updated")
                }
            }
            .listRowSeparator(.visible)
            .listSectionSeparator(.hidden)
        }
    }
}

#Preview(traits: .modifier(ShelfPreviewStore())) {
    @Previewable @Query var shelves: [Shelf]
    if let shelf = shelves.first {
        DesignSystem.FormList {
            ShelfPresentationPage(shelf: shelf)
        }
    }
}
