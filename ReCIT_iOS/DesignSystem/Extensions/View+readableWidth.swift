//
//  View+readableWidth.swift
//  ReCIT_iOS
//
//  Holds a column of content to `DesignSystem.ReadableWidth.maximum`, centred in whatever is
//  wider. Two shapes, because a scroll view's content cannot be framed from outside it:
//
//  - `readableWidth()` frames a block — the welcome screen's text and buttons, a sign-in
//    form's fields — and centres it.
//  - `readableContentMargins()` widens a `List`'s, `Form`'s or `ScrollView`'s horizontal
//    content margins, so the rows narrow while the scrolling surface and its background still
//    reach the screen's edges.
//
//  Both leave a phone exactly as it was.
//

import SwiftUI

extension View {
    /// At most `DesignSystem.ReadableWidth.maximum` wide, centred in the space it is given.
    func readableWidth() -> some View {
        frame(maxWidth: DesignSystem.ReadableWidth.maximum)
            .frame(maxWidth: .infinity)
    }

    /// A scroll view's content held to `DesignSystem.ReadableWidth.maximum`, its margins
    /// widened to centre it — and left to the list's own on a screen narrower than that, or
    /// when `isEnabled` is false (a page that lays its rows out in columns on a wide screen).
    func readableContentMargins(isEnabled: Bool = true) -> some View {
        modifier(ReadableContentMargins(isEnabled: isEnabled))
    }
}

/// Measures the scroll view and widens its horizontal content margins to suit.
private struct ReadableContentMargins: ViewModifier {
    let isEnabled: Bool

    @State private var containerWidth: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .contentMargins(
                .horizontal,
                isEnabled ? DesignSystem.ReadableWidth.scrollContentMargin(containerWidth: containerWidth) : nil,
                for: .scrollContent
            )
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.width
            } action: { width in
                containerWidth = width
            }
    }
}
