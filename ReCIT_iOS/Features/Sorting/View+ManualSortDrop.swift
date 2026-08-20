//
//  View+ManualSortDrop.swift
//  ReCIT_iOS
//
//  One drop destination of the sorting surface, in one line at each of the three
//  places that needs it: a book row, a section's empty-state note, a section header.
//
//  All three of a section's destinations report the **same section**, so wherever
//  inside the band the finger lets go, the drop lands on the section. Nowhere does it
//  land between two rows: order within an étagère is not part of the session's state
//  (PRD 0008), so an insertion point would promise a position the write cannot keep.
//
//  See PRD 0008.
//

import SwiftUI

extension View {

    /// Accepts a dragged book on behalf of `target.section`.
    ///
    /// - Parameters:
    ///   - target: this destination's identity, reported back on every targeting
    ///     change so the caller can tell one row's exit from another row's entry.
    ///   - onDrop: hands over the books that landed; returns whether the drop was ours.
    ///   - onTargeted: whether the finger is over this destination right now.
    func manualSortDropDestination(
        target: ManualSortDropTarget,
        onDrop: @escaping ([SortBookTransfer]) -> Bool,
        onTargeted: @escaping (Bool, ManualSortDropTarget) -> Void
    ) -> some View {
        dropDestination(for: SortBookTransfer.self) { transfers, _ in
            onDrop(transfers)
        } isTargeted: { isTargeted in
            onTargeted(isTargeted, target)
        }
    }
}
