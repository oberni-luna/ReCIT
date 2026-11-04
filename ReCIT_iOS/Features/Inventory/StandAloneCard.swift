//
//  StandAloneCard.swift
//  ReCIT_iOS
//

import SwiftUI

/// The card a `List` cell would give the row: margins, a ground, and the rounded corners the
/// long-press preview is cut to.
struct StandAloneCard: ViewModifier {
    let isOn: Bool

    func body(content: Content) -> some View {
        if isOn {
            content
                .padding(.horizontal, .medium)
                .padding(.vertical, .small)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.backgroundDefault)
                .contentShape(.contextMenuPreview, .rect(cornerRadius: .rounded))
        } else {
            content
        }
    }
}
