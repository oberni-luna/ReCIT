//
//  View+glass.swift
//  ReCIT_iOS
//
//  Liquid Glass where the system has it, the closest thing to it before. The app runs from
//  iOS 18, and glass only exists from iOS 26: these keep the `#available` out of the
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

    /// A glass capsule from iOS 26, a material capsule before it.
    @ViewBuilder
    func glassCapsule() -> some View {
        if #available(iOS 26.0, *) {
            glassEffect(.regular, in: .capsule)
        } else {
            background(.regularMaterial, in: .capsule)
        }
    }

    /// `GlassEffectContainer` from iOS 26, so neighbouring glass shapes blend; nothing before it.
    @ViewBuilder
    func glassEffectContainer() -> some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer { self }
        } else {
            self
        }
    }
}
