//
//  ManualSortSectionView.swift
//  ReCIT_iOS
//
//  One band of the sorting surface: a header, the books under it, and the whole thing
//  as one place to let go of a book.
//
//  **The drop lands on the section, never between two rows.** Order within an étagère
//  is not part of the session's state (PRD 0008) — the membership model carries none —
//  so an insertion point would promise a position the write could not keep. Every row
//  of the band therefore reports the *same* section as its destination, and the band
//  paints itself as the target as a whole, header included, which is what the design
//  draws.
//
//  The band cannot be one destination: a `List` section is not a view a modifier can
//  be hung on without ceasing to be a section, so each row carries its own. That is
//  why `ManualSortDropTarget` names a slot as well as a section — see its note.
//
//  See PRD 0008.
//

import SwiftUI

struct ManualSortSectionView: View {

    let section: SortSection

    /// What this band's pill says. Derived by the list from the write plan, which is
    /// the same reduction the recap and the apply read — so the pill, the sentence at
    /// the foot and what gets written cannot disagree (PRD 0008).
    let status: SortWritePlan.ShelfStatus

    /// Whether the finger is over this band right now. Owned by the list, which is the
    /// only place that can know a single section is the target.
    let isDropTarget: Bool

    /// How far the running apply has got with this étagère, or `nil` when there is no
    /// run or the run has nothing to do here.
    let mark: AutoSortApplyProgress.ShelfOutcome?

    let onDrop: ([SortBookTransfer]) -> Bool
    let onTargeted: (Bool, ManualSortDropTarget) -> Void

    var body: some View {
        Section {
            if section.books.isEmpty {
                ManualSortEmptySectionRow(isUnshelved: section.isUnshelved)
                    .manualSortDropDestination(
                        target: .init(section: section.id, slot: .placeholder),
                        onDrop: onDrop,
                        onTargeted: onTargeted
                    )
                    .listRowBackground(rowBackground)
            } else {
                ForEach(section.books) { book in
                    ManualSortBookRowView(book: book, section: section)
                        .manualSortDropDestination(
                            target: .init(section: section.id, slot: .book(book.id)),
                            onDrop: onDrop,
                            onTargeted: onTargeted
                        )
                        .listRowBackground(rowBackground)
                }
            }
        } header: {
            ManualSortSectionHeader(section: section, status: status, mark: mark)
                .manualSortDropDestination(
                    target: .init(section: section.id, slot: .header),
                    onDrop: onDrop,
                    onTargeted: onTargeted
                )
                .listRowBackground(headerBackground)
        }
    }

    /// A row rests on the card the list draws it in and turns `background/tinted` while
    /// the band is the target.
    private var rowBackground: Color {
        (isDropTarget ? DesignSystem.Color.backgroundTinted : .backgroundDefault).color
    }

    /// A header rests on the page, not on the card, so its resting value is nothing at
    /// all — it only ever gains a colour to say the band under it is receiving.
    private var headerBackground: Color {
        (isDropTarget ? DesignSystem.Color.backgroundTinted : .clear).color
    }
}
