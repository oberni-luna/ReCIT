//
//  NetworkNodeActivation.swift
//  ReCIT_iOS
//
//  A node of the Réseau graph as VoiceOver activates it: a button whose default action selects
//  it, as a touch on it does. « Vous » has none: touching it does nothing (Q28).
//

import SwiftUI

struct NetworkNodeActivation: ViewModifier {
    let onActivate: (() -> Void)?

    func body(content: Content) -> some View {
        if let onActivate {
            content
                .accessibilityAddTraits(.isButton)
                .accessibilityAction {
                    onActivate()
                }
        } else {
            content
        }
    }
}
