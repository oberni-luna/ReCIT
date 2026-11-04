//
//  ListKeyboardReveal.swift
//  ReCIT_iOS
//
//  Keeps a growing row above the keyboard, from behind it: an empty UIKit view set as the row's
//  background, which on every change of `trigger` finds the list's scroll view and moves it by
//  exactly what the row overruns the top of the keyboard.
//
//  **UIKit, because SwiftUI could not do it.** A `List` hands its rows to a collection view that
//  neither `ScrollViewReader` nor `ScrollPosition` moved on this screen — the cover flow's own
//  scroll view sits inside the list — and that does not follow a vertical field as it grows:
//  each new line of the comment went under the keyboard. The bridge does one thing, reads only
//  geometry, and touches nothing but the content offset.
//
//  The scroll view needs room below the row to move into: the screen adds a transparent row the
//  height of the keyboard while the comment is being written.
//
//  See PRD 0029.
//

import SwiftUI
import UIKit

struct ListKeyboardReveal: UIViewRepresentable {
    /// Changed on every edit, and on focus: each change is one look at whether the row is hidden.
    let trigger: Int
    /// The top of the keyboard on screen, `.infinity` when it is down.
    let keyboardTop: CGFloat
    /// Room kept between the row's foot and the keyboard.
    var margin: CGFloat = DesignSystem.Spacing.medium.rawValue

    func makeUIView(context: Context) -> UIView {
        let view: UIView = .init()
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ view: UIView, context: Context) {
        guard context.coordinator.trigger != trigger else { return }

        context.coordinator.trigger = trigger
        let keyboardTop: CGFloat = keyboardTop
        let margin: CGFloat = margin
        Task { @MainActor in
            // After the field has grown and the keyboard has landed.
            try? await Task.sleep(for: .milliseconds(120))
            Self.reveal(view, above: keyboardTop, margin: margin)
        }
    }

    func makeCoordinator() -> Coordinator {
        .init()
    }

    final class Coordinator {
        var trigger: Int?
    }

    private static func reveal(_ view: UIView, above keyboardTop: CGFloat, margin: CGFloat) {
        guard keyboardTop != .infinity, let scrollView = enclosingScrollView(of: view) else { return }

        let frame: CGRect = view.convert(view.bounds, to: nil)
        let overrun: CGFloat = frame.maxY + margin - keyboardTop
        guard overrun > 0 else { return }

        let maxOffset: CGFloat = scrollView.contentSize.height
            + scrollView.adjustedContentInset.bottom
            - scrollView.bounds.height
        let offset: CGFloat = min(scrollView.contentOffset.y + overrun, max(maxOffset, scrollView.contentOffset.y))
        scrollView.setContentOffset(.init(x: scrollView.contentOffset.x, y: offset), animated: true)
    }

    /// The nearest scroll view that scrolls vertically: the list, not a horizontal strip.
    private static func enclosingScrollView(of view: UIView) -> UIScrollView? {
        var candidate: UIView? = view.superview
        while let current = candidate {
            if let scrollView = current as? UIScrollView,
               scrollView.contentSize.height > scrollView.bounds.height || scrollView.alwaysBounceVertical {
                return scrollView
            }
            candidate = current.superview
        }
        return nil
    }
}
