//
//  CircularIconButtonStyle.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 04/08/2026.
//

import SwiftUI

/// A circular, tinted icon button sitting next to a primary pill — used for the
/// secondary actions (message, overflow) in the transaction action bar.
struct CircularIconButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .textStyle(.action300)
            .frame(width: 24, height: 24)
            .padding(.all, .medium)
            .background(isEnabled ? .backgroundTinted : .backgroundDisable)
            .foregroundStyle(isEnabled ? .foregroundTinted : .foregroundDisable)
            .clipShape(Circle())
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == CircularIconButtonStyle {
    static var circularIcon: Self {
        .init()
    }
}
