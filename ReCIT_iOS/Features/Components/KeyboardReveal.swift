//
//  KeyboardReveal.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 23/11/2026.
//
//  Keeps a growing field above the keyboard, from behind it: an empty UIKit view set as the
//  field's background, which finds the list's scroll view and moves it by exactly what the field
//  overruns the top of the keyboard — when the field takes the focus, when the keyboard lands or
//  changes, and on every change of `trigger`.
//
//  **UIKit, because SwiftUI could not do it.** A `List` hands its rows to a collection view that
//  neither `ScrollViewReader` nor `ScrollPosition` moved on a list's screen — the cover flow's own
//  scroll view sits inside the list — and that brings a vertical field into view by its top only:
//  the caret of a long note, and each new line, stayed under the keyboard. The bridge reads only
//  geometry, and touches nothing but the content offset.
//
//  It reads the keyboard's frame itself. Handed it by the screen, it missed the focus: the focus
//  came before the keyboard's frame, the reveal found no keyboard and gave up, and the frame
//  that followed did not ask again — the list's comment never rose.
//
//  The scroll view needs room below the field to move into: a list's screen adds a transparent
//  row the height of the keyboard while the comment is written; a page whose list the keyboard
//  reaches gets it from its bottom inset.
//

import SwiftUI
import UIKit

struct KeyboardReveal<Trigger: Equatable>: UIViewRepresentable {
    @MainActor
    final class Coordinator {
        weak var view: UIView?
        var isActive: Bool = false
        var trigger: Trigger?
        var margin: CGFloat = 0
        /// The top of the keyboard on screen, `.infinity` while it is down.
        private var keyboardTop: CGFloat = .infinity
        private var keyboardObservations: [Task<Void, Never>] = []

        init() {
            observeKeyboard()
        }

        deinit {
            keyboardObservations.forEach { $0.cancel() }
        }

        /// The nearest scroll view that scrolls vertically: the list, not a horizontal strip.
        private static func enclosingScrollView(of view: UIView) -> UIScrollView? {
            var candidate: UIView? = view.superview
            while let current = candidate {
                if let scrollView = current as? UIScrollView, scrollView.scrollsVertically {
                    return scrollView
                }
                candidate = current.superview
            }
            return nil
        }

        /// After the field has grown and the keyboard has landed.
        func revealSoon() {
            Task { [weak self] in
                try? await Task.sleep(for: .milliseconds(120))
                self?.reveal()
            }
        }

        private func observeKeyboard() {
            keyboardObservations = [
                Task { [weak self] in
                    for await notification in NotificationCenter.default.notifications(
                        named: UIResponder.keyboardWillChangeFrameNotification
                    ) {
                        let frame: CGRect? = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
                        self?.keyboardTop = frame?.minY ?? .infinity
                        if self?.isActive == true {
                            self?.revealSoon()
                        }
                    }
                },
                Task { [weak self] in
                    for await _ in NotificationCenter.default.notifications(
                        named: UIResponder.keyboardWillHideNotification
                    ) {
                        self?.keyboardTop = .infinity
                    }
                }
            ]
        }

        private func reveal() {
            guard
                isActive,
                keyboardTop != .infinity,
                let view,
                let scrollView = Self.enclosingScrollView(of: view)
            else {
                return
            }

            let frame: CGRect = view.convert(view.bounds, to: nil)
            let overrun: CGFloat = frame.maxY + margin - keyboardTop
            guard overrun > 0 else { return }

            let maxOffset: CGFloat = scrollView.contentSize.height
                + scrollView.adjustedContentInset.bottom
                - scrollView.bounds.height
            let offset: CGFloat = min(
                scrollView.contentOffset.y + overrun,
                max(maxOffset, scrollView.contentOffset.y)
            )
            scrollView.setContentOffset(.init(x: scrollView.contentOffset.x, y: offset), animated: true)
        }
    }

    /// Whether the field holds the focus: only that field moves the list.
    let isActive: Bool
    /// Changed as the field grows — its text, or a count of its edits.
    let trigger: Trigger
    /// Room kept between the field's foot and the keyboard.
    var margin: CGFloat = DesignSystem.Spacing.medium.rawValue

    func makeUIView(context: Context) -> UIView {
        let view: UIView = .init()
        view.isUserInteractionEnabled = false
        context.coordinator.view = view
        return view
    }

    func updateUIView(_ view: UIView, context: Context) {
        let coordinator: Coordinator = context.coordinator
        let becameActive: Bool = isActive && coordinator.isActive == false
        let grew: Bool = coordinator.trigger != trigger
        coordinator.isActive = isActive
        coordinator.trigger = trigger
        coordinator.margin = margin
        if isActive, becameActive || grew {
            coordinator.revealSoon()
        }
    }

    func makeCoordinator() -> Coordinator {
        .init()
    }
}

private extension UIScrollView {
    var scrollsVertically: Bool {
        contentSize.height > bounds.height || alwaysBounceVertical
    }
}
