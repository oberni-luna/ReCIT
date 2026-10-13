//
//  NetworkNodeAccessibilityElement.swift
//  ReCIT_iOS
//
//  A node of the Réseau graph as VoiceOver meets it (PRD 0019, Q44): one element — whatever the
//  node is drawn as, card, tile, avatar or dot, nothing inside it is reached on its own — with the
//  label `NetworkGraphAccessibility` wrote for it.
//
//  « Vous » is a heading and nothing more: touching it does nothing (Q28). Every other node is a
//  button whose default action selects it, as a touch does, and opens its sheet; its custom
//  actions do the sheet's gestures without it — Ouvrir le groupe or Voir le profil, and Accepter
//  and Refuser for what waits on me.
//

import SwiftUI

struct NetworkNodeAccessibilityElement: ViewModifier {
    /// What the node says and offers; `nil` until the graph is first described.
    let accessibility: NetworkNodeAccessibility?
    var isSelected: Bool = false
    /// What activating the node does, or `nil` for « Vous ».
    let onActivate: (() -> Void)?
    /// Does one of the node's custom actions.
    let onAction: (NetworkNodeAction) -> Void

    func body(content: Content) -> some View {
        content
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: accessibility?.label ?? ""))
            .accessibilityAddTraits(traits)
            .modifier(Activation(onActivate: onActivate))
            .accessibilityActions {
                // Reversed: SwiftUI hands UIKit the actions declared here last first (checked in
                // the simulator, issue 0110), and VoiceOver offers them in UIKit's order.
                ForEach((accessibility?.actions ?? []).reversed(), id: \.self) { action in
                    Button {
                        onAction(action)
                    } label: {
                        Text(action.title)
                    }
                }
            }
    }

    private var traits: AccessibilityTraits {
        if accessibility?.isHeader == true {
            return .isHeader
        }
        return isSelected ? [.isButton, .isSelected] : .isButton
    }

    /// The default action, for every node but « Vous ».
    private struct Activation: ViewModifier {
        let onActivate: (() -> Void)?

        func body(content: Content) -> some View {
            if let onActivate {
                content
                    .accessibilityHint(Text("network.graph.a11y.select_hint"))
                    .accessibilityAction {
                        onActivate()
                    }
            } else {
                content
            }
        }
    }
}
