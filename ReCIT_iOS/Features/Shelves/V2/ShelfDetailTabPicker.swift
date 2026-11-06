//
//  ShelfDetailTabPicker.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 06/11/2026.
//
//  Livres • 12 | Présentation, under an étagère's navigation bar: the `LensTabPicker` a list's
//  screen uses (`ListDetailTabPicker`), following the pager the two pages are in.
//
//  Reads the pager's position in its own body, so a swipe redraws the tabs and not the screen
//  that holds the pager.
//

import SwiftUI

struct ShelfDetailTabPicker: View {
    @Binding var selection: ShelfDetailTab
    let position: TabPagerPosition
    /// How many books the étagère holds, for the first tab's label.
    let count: Int

    var body: some View {
        LensTabPicker(selection: $selection, pagePosition: position.pagePosition) { tab in
            label(for: tab)
        }
        .accessibilityLabel("shelf.tabs")
    }

    @ViewBuilder
    private func label(for tab: ShelfDetailTab) -> some View {
        switch tab {
        case .books:
            Text("shelf.tab.books \(count)")
                .accessibilityLabel(Text("shelf.tab.books.accessibility \(count)"))
        case .presentation:
            Text("shelf.tab.presentation")
        }
    }
}

#Preview {
    @Previewable @State var selection: ShelfDetailTab = .books
    ShelfDetailTabPicker(
        selection: $selection,
        position: .init(),
        count: 12
    )
}
