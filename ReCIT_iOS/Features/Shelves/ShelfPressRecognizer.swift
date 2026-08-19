//
//  ShelfPressRecognizer.swift
//  ReCIT_iOS
//
//  Drives the shelf's press-and-scrub. It reports the touch the moment it lands (so the
//  book under the finger can start growing), arms selection mode after a hold, then
//  reports every move until the finger lifts. Until it arms it never claims the touch and
//  hands it back as soon as the finger travels, so a plain swipe still scrolls the
//  carousel. SwiftUI cannot compose hold-then-drag inside a snapping scroll view, which is
//  why this stays UIKit — the one deliberate exception. See ADR 0006.
//

import UIKit

final class ShelfPressRecognizer: UIGestureRecognizer {

    /// How long the finger must stay down before selection mode arms.
    static let holdDuration: TimeInterval = 0.5
    /// Travel allowed before arming; past it the touch belongs to the scroll view.
    static let slop: CGFloat = 10
    /// How far through the hold the veil starts coming in. Halfway, not sooner: a single tap
    /// would otherwise flash the whole screen for an instant.
    static let focusProgress: Double = 0.5

    var onPressBegan: ((CGPoint) -> Void)?
    /// The hold is nearly through: bring the focus in ahead of arming.
    var onFocusing: (() -> Void)?
    var onArmed: (() -> Void)?
    var onMoved: ((CGPoint) -> Void)?
    var onEnded: (() -> Void)?
    var onCancelled: (() -> Void)?

    private var startLocation: CGPoint = .zero
    private var armTask: Task<Void, Never>?
    private var isArmed: Bool = false

    override init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)
        // The shelf reacts through the closures; nothing else must lose its touches.
        cancelsTouchesInView = false
        delaysTouchesBegan = false
        delaysTouchesEnded = false
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        guard armTask == nil, let touch = touches.first else { return }
        startLocation = touch.location(in: view)
        onPressBegan?(startLocation)
        armTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(Self.holdDuration * Self.focusProgress))
            guard let self, Task.isCancelled == false, isArmed == false else { return }
            onFocusing?()
            try? await Task.sleep(for: .seconds(Self.holdDuration * (1 - Self.focusProgress)))
            guard Task.isCancelled == false, isArmed == false else { return }
            arm()
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        guard let touch = touches.first else { return }
        let location: CGPoint = touch.location(in: view)
        guard isArmed else {
            let travel: CGFloat = hypot(
                location.x - startLocation.x,
                location.y - startLocation.y
            )
            if travel > Self.slop { giveUp(.failed) }
            return
        }
        state = .changed
        onMoved?(location)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        guard isArmed else {
            giveUp(.failed)
            return
        }
        onEnded?()
        state = .ended
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesCancelled(touches, with: event)
        giveUp(.cancelled)
    }

    override func reset() {
        super.reset()
        armTask?.cancel()
        armTask = nil
        isArmed = false
    }

    private func arm() {
        isArmed = true
        state = .began
        onArmed?()
    }

    /// Ends the press without a selection: the finger travelled too soon, lifted too soon,
    /// or the system took the touch away.
    private func giveUp(_ endState: State) {
        armTask?.cancel()
        onCancelled?()
        state = endState
    }
}
