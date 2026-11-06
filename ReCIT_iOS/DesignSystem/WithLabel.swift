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

extension View {
    /// A value under its caption, as in a form: a list's or an étagère's Présentation.
    func infoRow(label: String) -> some View {
        textStyle(.content300)
            .foregroundStyle(.foregroundDefault)
            .withLabel(label: label)
    }
}

struct WithLabel: ViewModifier {
    let label: String?

    func body(content: Content) -> some View {
        VStack(alignment: .leading, spacing: .xSmall) {
            if let label {
                Text(.init(label))
                    .textStyle(.caption200)
                    .foregroundStyle(.foregroundSecondary)
            }

            content
        }
    }

}

#Preview {
    Text("Hello Olive")
        .withLabel(label: "Salutations")
}
