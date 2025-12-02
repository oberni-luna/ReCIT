//
//  ScaleButtonStyle.swift
//  Trompet
//
//  Created by Rémi Lanteri on 25/03/2025.
//

import SwiftUI

extension ButtonStyle where Self == ScaleButtonStyle {
    static var scaleButtonStyle: Self {
        Self()
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 1.2 : 1.0)
            .shadow(color: .shadow, radius: configuration.isPressed ? 8 : 0, y: configuration.isPressed ? 2 : 0)
            .onChange(of: configuration.isPressed) { isPressed in
                guard !isPressed else { return }
                Haptics.Impact.light.play()
            }
            .animation(.bouncy(duration: 0.1, extraBounce: 0.2), value: configuration.isPressed)
    }
}
