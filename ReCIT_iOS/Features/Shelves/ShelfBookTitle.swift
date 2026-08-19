//
//  ShelfBookTitle.swift
//  ReCIT_iOS
//
//  A book's title as it reads on the shelf: set along the spine when it stands, straight when
//  it lies flat. Shared by the shelf and by the focus overlay that redraws the pressed book,
//  so both read the same. See ADR 0006.
//

import SwiftUI

struct ShelfBookTitle: View {
    let title: String
    /// Colour picked for legibility against the book's own cover.
    let ink: Color
    let orientation: ShelfBookOrientation
    let size: CGSize

    var body: some View {
        switch orientation {
        case .standing:
            text
                .frame(width: max(size.height - 12, 10))
                .rotationEffect(.degrees(-90))
        case .lying:
            text
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 6)
        }
    }

    private var text: some View {
        Text(title)
            .textStyle(.footnote200Bold)
            .foregroundStyle(ink)
            .shadow(color: .black.opacity(0.45), radius: 1, x: 0, y: 0.5)
            .lineLimit(1)
            .truncationMode(.tail)
    }
}
