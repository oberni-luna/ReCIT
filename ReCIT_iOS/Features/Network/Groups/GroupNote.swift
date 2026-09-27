//
//  GroupNote.swift
//  ReCIT_iOS
//
//  The footnote under a group's buttons that says what a gesture costs — the same sentence
//  style `RelationActionsView` puts under a reader's (`Note`, Footnote, Secondary).
//

import SwiftUI

struct GroupNote: View {
    let text: LocalizedStringKey

    init(_ text: LocalizedStringKey) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .textStyle(.footnote200)
            .foregroundStyle(.foregroundSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
