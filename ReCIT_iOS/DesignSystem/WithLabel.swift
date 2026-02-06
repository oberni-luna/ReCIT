//
//  WithLabel.swift
//  DesignSystem
//
//  Created by Olivier Berni
//

import SwiftUI

public extension View {
    func withLabel(label: String?) -> some View {
        self.modifier(WithLabel(label: label))
    }
}

struct WithLabel: ViewModifier {
    let label: String?

    func body(content: Content) -> some View {
        VStack(alignment: .leading, spacing: .xSmall) {
            if let label {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .bold()
            }

            content
        }
    }


}

#Preview {
    Text("Hello Olive")
        .withLabel(label: "Salutations")
}
