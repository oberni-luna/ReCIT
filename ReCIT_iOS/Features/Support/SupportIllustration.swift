//
//  SupportIllustration.swift
//  ReCIT_iOS
//
//  The donation sheet's picture: the app icon's books on their shelf, standing on the watercolour
//  wash every étagère is painted on. What is being supported, shown before it is named.
//

import SwiftUI

struct SupportIllustration: View {
    private let side: CGFloat = 176
    /// The wash spreads wider than the books, as it does under a shelf.
    private let washWidth: CGFloat = 330

    var body: some View {
        ZStack {
            Image("ShelfWash")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: washWidth)
                .opacity(0.92)
            Image(.booksOnShelf)
                .resizable()
                .scaledToFit()
                .frame(width: side, height: side)
        }
        .frame(height: side)
        .accessibilityHidden(true)
    }
}

#Preview {
    SupportIllustration()
}
