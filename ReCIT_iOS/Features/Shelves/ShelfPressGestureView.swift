//
//  ShelfPressGestureView.swift
//  ReCIT_iOS
//
//  Thin SwiftUI bridge over `ShelfPressRecognizer`: an invisible view laid over a shelf
//  card that turns the press-and-scrub into closures. Positions are in the card's own
//  coordinates and may fall outside it once the finger wanders. See ADR 0006.
//

import SwiftUI
import UIKit

struct ShelfPressGestureView: UIViewRepresentable {
    /// The touch landed: the book under it starts growing.
    var onPressBegan: (CGPoint) -> Void
    /// The hold is nearly through: the surroundings start to blur.
    var onFocusing: () -> Void
    /// The hold completed: selection mode is on.
    var onArmed: () -> Void
    /// The finger moved while selection mode is on.
    var onMoved: (CGPoint) -> Void
    /// The finger lifted while selection mode is on.
    var onEnded: () -> Void
    /// The press ended with nothing selected. The reason says which: a lift is a tap and
    /// settles back gently, a travel means the scroll view has the touch and the copy has to
    /// go at once.
    var onCancelled: (ShelfPressRecognizer.Cancellation) -> Void

    func makeCoordinator() -> Coordinator { .init(self) }

    func makeUIView(context: Context) -> UIView {
        let view: UIView = .init()
        view.backgroundColor = .clear

        let coordinator: Coordinator = context.coordinator
        let press: ShelfPressRecognizer = .init(target: nil, action: nil)
        press.delegate = coordinator
        press.onPressBegan = { [weak coordinator] in coordinator?.parent.onPressBegan($0) }
        press.onFocusing = { [weak coordinator] in coordinator?.parent.onFocusing() }
        press.onArmed = { [weak coordinator] in coordinator?.parent.onArmed() }
        press.onMoved = { [weak coordinator] in coordinator?.parent.onMoved($0) }
        press.onEnded = { [weak coordinator] in coordinator?.parent.onEnded() }
        press.onCancelled = { [weak coordinator] in coordinator?.parent.onCancelled($0) }

        view.addGestureRecognizer(press)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.parent = self
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var parent: ShelfPressGestureView

        init(_ parent: ShelfPressGestureView) { self.parent = parent }

        /// Coexist with the carousel's pan: before arming, a swipe must still scroll.
        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            true
        }
    }
}
