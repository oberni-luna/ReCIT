//
//  DesignSystem+Form.swift
//  ReCIT_iOS
//
import SwiftUI

extension DesignSystem {
    /// A `Form` on the form's own ground, its rows on the form's card.
    ///
    /// `backgroundForm` behind, `backgroundFormCell` under every row: white on grey in light,
    /// a darker grey on grey in dark, like the book screen. A row that sets its own
    /// `listRowBackground` keeps it.
    ///
    /// The title is always inline: a large one says nothing the form's first field does not,
    /// and on a wide screen it sat at the bar's margin while the rows narrowed to the readable
    /// column.
    struct Form<Content: View>: View {
        @ViewBuilder let content: Content

        var body: some View {
            SwiftUI.Form {
                content
                    .listRowBackground(DesignSystem.Color.backgroundFormCell.color)
            }
            .applyListBackground(.backgroundForm)
            .readableContentMargins()
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
