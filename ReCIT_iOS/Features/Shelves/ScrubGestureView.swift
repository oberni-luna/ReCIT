//
//  ScrubGestureView.swift
//  ReCIT_iOS
//
//  A thin UIKit bridge for the shelf scrub. SwiftUI can't compose "hold then drag"
//  inside a snapping scroll view without either blocking the scroll or dropping the
//  in-progress touch, so a UILongPressGestureRecognizer drives it instead. It recognises
//  simultaneously with the carousel's scroll, so a plain swipe still scrolls; only a
//  ~0.2s press then a slide scrubs. A tap opens the shelf list. This is the single,
//  deliberate UIKit exception. See PRD 0002.
//

import SwiftUI
import UIKit

struct ScrubGestureView: UIViewRepresentable {
    var onTap: () -> Void
    var onScrubBegan: () -> Void
    var onScrubChanged: (CGPoint) -> Void
    var onScrubEnded: (_ location: CGPoint, _ cancelled: Bool) -> Void

    func makeCoordinator() -> Coordinator { .init(self) }

    func makeUIView(context: Context) -> UIView {
        let view: UIView = .init()
        view.backgroundColor = .clear

        let longPress: UILongPressGestureRecognizer = .init(
            target: context.coordinator,
            action: #selector(Coordinator.handleLongPress(_:))
        )
        longPress.minimumPressDuration = 0.2
        longPress.delegate = context.coordinator

        let tap: UITapGestureRecognizer = .init(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap)
        )
        tap.delegate = context.coordinator

        view.addGestureRecognizer(longPress)
        view.addGestureRecognizer(tap)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.parent = self
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var parent: ScrubGestureView

        init(_ parent: ScrubGestureView) { self.parent = parent }

        @objc func handleTap() {
            parent.onTap()
        }

        @objc func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
            let location: CGPoint = recognizer.location(in: recognizer.view)
            switch recognizer.state {
            case .began:
                parent.onScrubBegan()
                parent.onScrubChanged(location)
            case .changed:
                parent.onScrubChanged(location)
            case .ended:
                parent.onScrubEnded(location, false)
            case .cancelled, .failed:
                parent.onScrubEnded(location, true)
            default:
                break
            }
        }

        // Coexist with the carousel's pan and with each other.
        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            true
        }
    }
}
