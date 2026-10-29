//
//  FormActionBar.swift
//  ReCIT_iOS
//
//  The bar a long form pins at its foot, so that its action is in reach without scrolling to the
//  end. `Action Bar / Attached` in the Figma file without its round buttons: the content padded,
//  on no surface of its own. Pinned through `formActionBar(_:)`, never placed by hand.
//
//  From iOS 26 the bar is a `safeAreaBar` and the form's scroll view fades its content out under
//  it with the system's soft scroll edge effect, so the button sits on the form itself. Before
//  iOS 26 there is no such effect: the bar is a `safeAreaInset` on the thin material, under a
//  hairline, down to the screen's bottom edge.
//

import SwiftUI

struct FormActionBar<Content: View>: View {
    let isPresented: Bool
    let isOnMaterial: Bool
    let content: Content

    var body: some View {
        if isPresented {
            bar
        }
    }

    private var bar: some View {
        VStack(spacing: .zero) {
            if isOnMaterial {
                Divider()
            }

            content
                .padding(.horizontal, .medium)
                .padding(.vertical, .sMedium)
        }
        .background {
            if isOnMaterial {
                Rectangle()
                    .fill(.thinMaterial)
                    .ignoresSafeArea(edges: .bottom)
            }
        }
    }
}

extension View {
    /// Pins `content` at the foot of this form: over a soft scroll edge from iOS 26, on the thin
    /// material before it. `isPresented` takes the bar away — hairline and material with it —
    /// without taking the modifier off, so the form keeps its identity when its actions end.
    @ViewBuilder
    func formActionBar<Content: View>(
        isPresented: Bool = true,
        @ViewBuilder _ content: () -> Content
    ) -> some View {
        let bar: Content = content()
        if #available(iOS 26.0, *) {
            safeAreaBar(edge: .bottom) {
                FormActionBar(
                    isPresented: isPresented,
                    isOnMaterial: false,
                    content: bar
                )
            }
            .scrollEdgeEffectStyle(.soft, for: .bottom)
        } else {
            safeAreaInset(edge: .bottom) {
                FormActionBar(
                    isPresented: isPresented,
                    isOnMaterial: true,
                    content: bar
                )
            }
        }
    }
}
