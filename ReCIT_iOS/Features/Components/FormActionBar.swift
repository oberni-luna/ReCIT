//
//  FormActionBar.swift
//  ReCIT_iOS
//
//  The bar a long form pins at its foot, through `safeAreaInset(edge: .bottom)`, so that its
//  action is in reach without scrolling to the end. `Action Bar / Attached` in the Figma file
//  without its round buttons: `background/default`, a hairline above, the content padded.
//

import SwiftUI

struct FormActionBar<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: .zero) {
            Divider()

            content()
                .padding(.horizontal, .medium)
                .padding(.vertical, .sMedium)
        }
        .background(.backgroundDefault)
    }
}
