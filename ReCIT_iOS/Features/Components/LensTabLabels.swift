//
//  LensTabLabels.swift
//  ReCIT_iOS
//
//  The row of a `LensTabPicker`'s words in one colour. The picker lays it twice: once in grey,
//  holed where the capsule is, and once in the selected colour, seen only through the capsule and
//  magnified while it is lifted. Only the grey row is measured and read by VoiceOver.
//

import SwiftUI

struct LensTabLabels<Tab: CaseIterable & Hashable, Label: View>: View {
    let color: DesignSystem.Color
    /// The grey row's: each word's frame in `coordinateSpace`, for the capsule to be drawn
    /// between, and the selection VoiceOver reads and changes. `nil` on the lens's copy.
    var measuring: (
        selection: Binding<Tab>,
        coordinateSpace: String,
        onFrame: (Tab, CGRect) -> Void
    )?
    let label: (Tab) -> Label

    var body: some View {
        HStack(spacing: .zero) {
            ForEach(Array(Tab.allCases), id: \.self) { tab in
                let word = label(tab)
                    .textStyle(.action200)
                    .foregroundStyle(color)
                    // At the largest text sizes, shrunk rather than wrapped or cut.
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, .sMedium)
                    .padding(.vertical, .small)

                if let measuring {
                    word
                        .onGeometryChange(for: CGRect.self) {
                            $0.frame(in: .named(measuring.coordinateSpace))
                        } action: { frame in
                            measuring.onFrame(tab, frame)
                        }
                        // The touches are the picker's drag; VoiceOver still sees one button a word.
                        .accessibilityElement(children: .combine)
                        .accessibilityAddTraits(.isButton)
                        .accessibilityAddTraits(tab == measuring.selection.wrappedValue ? .isSelected : [])
                        .accessibilityAction {
                            measuring.selection.wrappedValue = tab
                        }
                } else {
                    word
                }
            }
        }
    }
}
