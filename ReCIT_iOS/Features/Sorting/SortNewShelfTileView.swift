//
//  SortNewShelfTileView.swift
//  ReCIT_iOS
//
//  The last cell of the étagère grid: a card-shaped invitation to make another étagère.
//
//  **It replaces the « + » in the navigation bar.** Creating an étagère mid-sort is a
//  documented use of this screen — the scheme grows while the books are being filed — and at
//  that moment the eye is in the grid, not in the bar. One action, one control, at the place
//  it is used (PRD 0009).
//
//  **It is also a drop target**, which is what makes "make a shelf for this book" one
//  movement: dropping a book opens the create form, and confirming creates the étagère with
//  that book already on it. Cancelling leaves no trace — the book never moved.
//
//  And it is the screen's empty state: a library with no étagère shows this tile alone, which
//  says what to do without a screen of its own to draw and maintain.
//

import SwiftUI

struct SortNewShelfTileView: View {
    let width: CGFloat
    /// Whether the tile takes gestures. False while a run owns the stack.
    let isActive: Bool
    let onTap: () -> Void
    /// Opens the form with a book in hand. Returns whether the drop was taken.
    let onDrop: (String) -> Bool

    @State private var isTargeted: Bool = false

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: .xSmall) {
                Image(systemName: "plus")
                    .foregroundStyle(.foregroundTinted)
                    .frame(height: SortGridMetrics.artHeight)

                Text("manual_sort.create_shelf")
                    .textStyle(.footnote200Bold)
                    .foregroundStyle(.foregroundTinted)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(.vertical, .small)
            .padding(.horizontal, .xSmall)
            .frame(width: width, height: SortGridMetrics.cardHeight)
            .background(DesignSystem.Color.backgroundTinted.color)
            .clipShape(.rect(cornerRadius: DesignSystem.CornerRadius.rounded.rawValue))
            .overlay {
                RoundedRectangle(cornerRadius: .rounded)
                    .strokeBorder(
                        DesignSystem.Color.borderTinted.color,
                        style: .init(lineWidth: isTargeted ? 2 : 1, dash: isTargeted ? [] : [4, 4])
                    )
            }
            .scaleEffect(isTargeted ? 1.03 : 1)
            .animation(.easeOut(duration: 0.15), value: isTargeted)
        }
        .buttonStyle(.plain)
        .disabled(isActive == false)
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
