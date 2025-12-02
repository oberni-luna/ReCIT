//
//  TagToggleStyle.swift
//  Trompet
//
//  Created by Rémi Lanteri on 30/06/2025.
//

import SwiftUI

extension ToggleStyle where Self == TagToggleStyle {
    static var tagToggleStyle: Self {
        Self()
    }
}

struct TagToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .textStyle(.footnote200)
            .foregroundStyle(configuration.isOn ? .textOnTint : .textSecondary)
            .padding(.all, .small)
            .lineLimit(1)
            .background {
                if configuration.isOn {
                    RoundedRectangle(cornerRadius: .medium)
                        .fill(.surfaceTintPrimary)
                } else {
                    RoundedRectangle(cornerRadius: .medium)
                        .strokeBorder(.borderTertiary, lineWidth: Constant.borderWidth)
                }
            }
            .onTapGesture {
                configuration.isOn.toggle()
            }
    }
}

private extension Constant {
    static let borderWidth: CGFloat = 1
}
