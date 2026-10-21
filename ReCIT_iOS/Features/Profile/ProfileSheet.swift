//
//  ProfileSheet.swift
//  ReCIT_iOS
//
//  The profile, as the sheet the avatar opens. It was the last tab of the bar until feature 0038.
//
//  It brings a `ShelfFocusModel` of its own, and the overlay that goes with it: a transaction
//  leads to a reader, a reader to their étagères, and pressing a book there needs a focus to
//  write to and a veil drawn over *this* sheet. The tab view's overlay would sit underneath it.
//

import SwiftUI

struct ProfileSheet: View {
    @State private var shelfFocus: ShelfFocusModel = .init()

    var body: some View {
        ProfileView()
            .environment(shelfFocus)
            .overlay {
                if shelfFocus.isPressing {
                    ShelfFocusOverlayView(focus: shelfFocus)
                }
            }
    }
}
