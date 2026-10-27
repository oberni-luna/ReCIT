//
//  DesignSystem+FormList.swift
//  ReCIT_iOS
//
import SwiftUI

extension DesignSystem {
    /// A `List` pushed from a form — a picker, a search — painted like `DesignSystem.Form`,
    /// so the flow keeps one ground from screen to screen, with the same inline title.
    struct FormList<Content: View>: View {
        @ViewBuilder let content: Content

        var body: some View {
            List {
                content
                    .listRowBackground(DesignSystem.Color.backgroundFormCell.color)
            }
            .applyListBackground(.backgroundForm)
            .readableContentMargins()
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
