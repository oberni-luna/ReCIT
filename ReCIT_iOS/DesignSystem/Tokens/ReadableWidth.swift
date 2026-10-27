//
//  ReadableWidth.swift
//  ReCIT_iOS
//
//  How wide a column of text, fields and cards may grow before it stops being read as one.
//
//  Every phone is narrower than this, so on a phone nothing changes. The unfolded iPhone Duo is
//  not: 669 pt in portrait, 951 in landscape, where a sign-in field or a book's cards ran some
//  880 pt across. Above the ceiling the column keeps its width and centres itself.
//

import CoreGraphics

extension DesignSystem {

    enum ReadableWidth {
        /// The widest the column grows.
        static let maximum: CGFloat = 540

        /// The horizontal margin that brings a scrolling list or form in a container
        /// `containerWidth` wide down to `maximum`, or `nil` — keep the list's own margins —
        /// where those already leave the column narrower than that, as on every phone.
        static func scrollContentMargin(containerWidth: CGFloat) -> CGFloat? {
            let margin: CGFloat = (containerWidth - maximum) / 2
            return margin > listMargin ? margin : nil
        }

        /// The margin a grouped list keeps at its edges on its own.
        static let listMargin: CGFloat = 20
    }
}
