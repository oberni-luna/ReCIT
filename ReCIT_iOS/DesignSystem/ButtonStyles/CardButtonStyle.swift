//
//  CardButtonStyle.swift
//  Trompet
//
//  Created by Rémi Lanteri on 23/06/2025.
//

import SwiftUI

extension ButtonStyle where Self == CardButtonStyle {
    static var cardButtonStyle: Self {
        Self()
    }
}

struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .shadow(color: DesignSystem.Color.shadowTint.color, radius: configuration.isPressed ? 1 : 6, x: 0, y: configuration.isPressed ? 1 : 2)
            .onChange(of: configuration.isPressed) { _, isPressed in
                guard !isPressed else { return }
                Haptics.Impact.light.play()
            }
            .animation(.smooth(duration: 0.15), value: configuration.isPressed)
    }
}
