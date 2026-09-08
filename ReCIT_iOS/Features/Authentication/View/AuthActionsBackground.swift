//
//  AuthActionsBackground.swift
//  ReCIT_iOS
//
//  The ground under the account screens' bottom bar: the same green as the screen, with the top
//  edge of it faded in rather than drawn.
//
//  The bar is a `safeAreaInset`, so the form scrolls *under* it. Painted as a flat rectangle,
//  its top edge is a hard line across the screen that a sentence disappears behind mid-word —
//  on a green screen, where the bar and the form are the same colour, that line is the only
//  thing announcing there are two surfaces. Faded, the form dissolves into the bar and the
//  buttons look like they are standing on the screen rather than on a panel.
//
//  The ramp is `xLarge` tall and starts `small` **above** the bar — hence the negative top
//  padding, and hence a background rather than a fill on the bar itself. Ending the fade exactly
//  where the first button starts is the point: a ramp that runs on under the button puts a
//  gradient behind a capsule, which reads as a shadow nobody asked for.
//
//  The colour is `backgroundTinted` throughout, and its transparent end is that same token at
//  zero opacity — never a `.clear`, which on some renderers fades through black and greys the
//  ramp on its way down.
//

import SwiftUI

struct AuthActionsBackground: View {
    private static let ground: Color = DesignSystem.Color.backgroundTinted.color

    var body: some View {
        VStack(spacing: .zero) {
            LinearGradient(
                colors: [Self.ground.opacity(0), Self.ground],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: DesignSystem.Spacing.xLarge.rawValue)

            Self.ground
        }
        .padding(.top, -DesignSystem.Spacing.small.rawValue)
        // Down to the very bottom of the screen: the bar stops at the home indicator, and the
        // green has to carry on under it.
        .ignoresSafeArea(edges: .bottom)
    }
}

#Preview {
    VStack(spacing: .zero) {
        Text("Le formulaire qui passe dessous")
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        Button("Se connecter") {}
            .buttonStyle(.primary())
            .padding(.horizontal, .medium)
            .padding(.vertical, .large)
            .background { AuthActionsBackground() }
    }
    .background(.backgroundTinted)
    .preferredColorScheme(.dark)
}
