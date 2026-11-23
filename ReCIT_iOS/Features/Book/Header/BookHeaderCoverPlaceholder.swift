//
//  BookHeaderCoverPlaceholder.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 22/11/2026.
//

import SwiftUI

/// A cover's shape while it loads, or for good when the edition has none: the header keeps its
/// layout, and so does the fold measured from it.
struct BookHeaderCoverPlaceholder: View {
    var body: some View {
        DesignSystem.Color.backgroundDisable.color
            .aspectRatio(2 / 3, contentMode: .fit)
            .overlay {
                Image(systemName: "book.closed")
                    .textStyle(.title200)
                    .foregroundStyle(.foregroundSecondary)
            }
            .accessibilityHidden(true)
    }
}

#Preview {
    BookHeaderCoverPlaceholder()
        .frame(height: 256)
}
