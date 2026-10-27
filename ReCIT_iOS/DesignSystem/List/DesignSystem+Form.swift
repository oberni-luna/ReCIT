//
//  DesignSystem+Form.swift
//  ReCIT_iOS
//
import SwiftUI

extension DesignSystem {
    /// A `Form` on the form's own ground, its rows on the form's card.
    ///
    /// `backgroundForm` behind, `backgroundFormCell` under every row: grey under white in
    /// light, black under grey in dark. A row that sets its own `listRowBackground` keeps it.
    struct Form<Content: View>: View {
        @ViewBuilder let content: Content

        var body: some View {
            SwiftUI.Form {
                content
                    .listRowBackground(DesignSystem.Color.backgroundFormCell.color)
            }
            .applyListBackground(.backgroundForm)
        }
    }
}
