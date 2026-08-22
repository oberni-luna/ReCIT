//
//  SortShelfCardCell.swift
//  ReCIT_iOS
//
//  One cell of the étagère grid: the card, the tap that opens it, and the drop that files a
//  book onto it.
//
//  It is a view of its own because the highlight is **per card** — `dropDestination` hands
//  its `isTargeted` to a binding, and a binding needs somewhere to live. Held by the grid in
//  a dictionary it would be one more thing to keep in step with the sections.
//
//  The haptic fires on **entry only**. A buzz on every exit turns a hesitant hand hovering
//  between two étagères into a rattle.
//
//  The whole card is the target, title included: 158 pt of height to aim at rather than the
//  106 pt of art, and the title is the one part of the card a finger does not cover.
//

import SwiftUI

struct SortShelfCardCell: View {
    let section: SortSection
    let status: SortWritePlan.ShelfStatus
    let width: CGFloat
    /// Whether this card accepts drops and hands over its front book. False while a run owns
    /// the stack: the session refuses the write anyway, and a drag that starts and achieves
    /// nothing is worse than one that cannot start.
    let isActive: Bool
    /// Files the carried book onto this étagère. Returns whether the drop was taken.
    let onDrop: (String) -> Bool

    @State private var isTargeted: Bool = false

    var body: some View {
        NavigationLink(value: section.id) {
            SortShelfCardView(
                section: section,
                status: status,
                width: width,
                isTargeted: isTargeted,
                isDraggable: isActive
            )
        }
        // Plain: the card is its own visual, and a link style that tinted or chevroned it
        // would fight both the pile and the drop highlight.
        .buttonStyle(.plain)
        .dropDestination(for: SortBookTransfer.self) { transfers, _ in
            guard isActive, let transfer = transfers.first else { return false }
            return onDrop(transfer.bookId)
        } isTargeted: { targeted in
            isTargeted = targeted && isActive
        }
        .onChange(of: isTargeted) { _, targeted in
            guard targeted else { return }
            Haptics.Impact.soft.play()
        }
    }
}
