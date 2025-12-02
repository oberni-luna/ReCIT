//
//  ButtonPressedEffect.swift
// Trompet
//
//  Created by Quentin Noblet on 14/11/2024.
//

import SwiftUI

extension ButtonStyleConfiguration.Label {
    public func defaultPressedEffect(isPressed: Bool) -> some View {
        self
            .scaleEffect(isPressed ? 0.7 : 1)
            .animation(.easeOut(duration: 0.2), value: isPressed)
            .opacity(isPressed ? 0.7 : 1)
    }
}
