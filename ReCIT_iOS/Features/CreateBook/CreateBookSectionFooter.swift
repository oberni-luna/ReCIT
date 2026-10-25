//
//  CreateBookSectionFooter.swift
//  ReCIT_iOS
//
//  The sentence under a section of the book creation, in the app's footnote rather than the
//  system's: `Note` (`101:236`), Footnote / Secondary, in the Figma file.
//
//  See PRD 0026.
//

import SwiftUI

struct CreateBookSectionFooter: View {
    let text: LocalizedStringKey

    init(_ text: LocalizedStringKey) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .textStyle(.footnote200)
            .foregroundStyle(.foregroundSecondary)
    }
}
