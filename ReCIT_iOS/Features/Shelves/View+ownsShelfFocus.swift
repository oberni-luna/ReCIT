//
//  View+ownsShelfFocus.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 16/11/2026.
//

import SwiftUI

extension View {
    /// A `ShelfFocusModel` of its own, and the veil it draws over this view. For a sheet that
    /// leads to a reader's étagères: pressing a book there needs a focus to write to and a veil
    /// drawn over *this* sheet, and the tab view's would sit underneath it.
    func ownsShelfFocus() -> some View {
        modifier(ShelfFocusOwning())
    }
}

private struct ShelfFocusOwning: ViewModifier {
    @State private var shelfFocus: ShelfFocusModel = .init()

    func body(content: Content) -> some View {
        content
            .environment(shelfFocus)
            .overlay {
                if shelfFocus.isPressing {
                    ShelfFocusOverlayView(focus: shelfFocus)
                }
            }
    }
}
