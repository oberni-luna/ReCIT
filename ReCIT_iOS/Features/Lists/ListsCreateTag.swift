//
//  ListsCreateTag.swift
//  ReCIT_iOS
//
//  « Créer une liste », on the same paper as the empty shelf's action tags: a glyph and a
//  title, then a few words of what a list may hold. It opens the same form as the « + » in
//  the navigation bar — the tag is a way to it, not a second one.
//

import SwiftUI

struct ListsCreateTag: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: .xSmall) {
                Label {
                    Text("lists.empty.action.create.title")
                        .textStyle(.content400Bold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                } icon: {
                    Image(systemName: "plus")
                }

                Text("lists.empty.action.create.detail")
                    .textStyle(.footnote200)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .accessibilityHidden(true)
            }
            .foregroundStyle(ShelfPalette.labelInk)
            .padding(.horizontal, .medium)
            .padding(.vertical, .sMedium)
            .shelfPaper(text: String(localized: "lists.empty.action.create.title"))
        }
        .buttonStyle(.plain)
        .accessibilityHint(Text("lists.empty.action.create.detail"))
        .accessibilityIdentifier("e2e.lists.empty.create")
    }
}
