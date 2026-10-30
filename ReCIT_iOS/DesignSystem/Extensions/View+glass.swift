//
//  View+glass.swift
//  ReCIT_iOS
//
//  Liquid Glass where the system has it, the closest thing to it before. The app runs from
//  iOS 18, and glass only exists from iOS 26: these two keep the `#available` out of the
//  screens that use it.
//

import SwiftUI

extension View {
    /// `.buttonStyle(.glass)` from iOS 26, `.bordered` before it.
    @ViewBuilder
    func glassButtonStyle() -> some View {
        if #available(iOS 26.0, *) {
            buttonStyle(.glass)
        } else {
            buttonStyle(.bordered)
        }
    }

    /// An interactive glass circle from iOS 26, a material circle before it.
    @ViewBuilder
    func interactiveGlassCircle() -> some View {
        if #available(iOS 26.0, *) {
            glassEffect(.regular.interactive(), in: .circle)
        } else {
            background(.regularMaterial, in: .circle)
        }
    }

    /// A glass capsule from iOS 26, a material capsule before it — the selected tab of a
    /// strip of tabs, as in the Contacts card.
    @ViewBuilder
    func glassCapsule() -> some View {
        if #available(iOS 26.0, *) {
            glassEffect(.regular, in: .capsule)
        } else {
            background(.regularMaterial, in: .capsule)
        }
    }

    /// The top edge's soft scroll-edge blur turned off from iOS 26, for a screen that draws its
    /// own backdrop under the navigation bar. Nothing to turn off before.
    @ViewBuilder
    func topScrollEdgeEffectHidden() -> some View {
        if #available(iOS 26.0, *) {
            scrollEdgeEffectHidden(true, for: .top)
        } else {
            self
        }
    }
}
