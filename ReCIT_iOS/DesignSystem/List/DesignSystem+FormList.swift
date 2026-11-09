//
//  DesignSystem+FormList.swift
//  ReCIT_iOS
//
import SwiftUI

extension DesignSystem {
    /// A `List` pushed from a form — a picker, a search — painted like `DesignSystem.Form`,
    /// so the flow keeps one ground from screen to screen, with the same inline title.
    /// Section headers read as typed, as from iOS 26: iOS 18 would put them in capitals.
    struct FormList<Content: View>: View {
        @ViewBuilder let content: Content

        var body: some View {
            List {
                content
                    .listRowBackground(DesignSystem.Color.backgroundFormCell.color)
                    .textCase(nil)
            }
            .applyListBackground(.backgroundForm)
            .readableContentMargins()
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
