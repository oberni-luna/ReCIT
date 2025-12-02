//
//  RadioToggleStyle.swift
//  Trompet
//
//  Created by Rémi Lanteri on 30/06/2025.
//

import SwiftUI

extension ToggleStyle where Self == RadioToggleStyle {
    static var radioToggleStyle: Self {
        Self()
    }
}

struct RadioToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .center) {
            if #available(iOS 17.0, *) {
                radioButton(isSelected: configuration.isOn)
                    .contentTransition(.symbolEffect(.automatic, options: .speed(2)))
            } else {
                radioButton(isSelected: configuration.isOn)
            }
            configuration.label
                .multilineTextAlignment(.leading)
                .foregroundStyle(.textDefault)
                .textStyle(.content400)
        }
        .padding(.vertical, .xxSmall)
        .padding(.horizontal, .sMedium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .onTapGesture {
            configuration.isOn.toggle()
        }
    }

    private func radioButton(isSelected: Bool) -> some View {
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
            .foregroundStyle(.surfaceTintPrimary)
    }
}
