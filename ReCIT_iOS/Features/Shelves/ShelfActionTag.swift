//
//  ShelfActionTag.swift
//  ReCIT_iOS
//
//  One action on the empty shelf, written on a paper tag resting on the plank: a glyph and a
//  title on the first line, a few words of how on the second. It is the shelf's own kind of
//  button — the same paper as an étagère's name tag, so the empty card reads as a shelf
//  waiting for books rather than a form with buttons pasted on it.
//
//  The whole tag is the target and nothing around it: with two tags side by side, the gap
//  between them must not open either one.
//

import SwiftUI

struct ShelfActionTag: View {
    let action: ShelfEmptyStateAction
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: .xSmall) {
                Label {
                    Text(action.title)
                        .textStyle(.content400Bold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                } icon: {
                    Image(systemName: action.systemImage)
                }
                .foregroundStyle(ShelfPalette.labelInk)

                Text(action.detail)
                    .textStyle(.footnote200)
                    .foregroundStyle(ShelfPalette.labelInk)
                    .lineLimit(2)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, .medium)
            .padding(.vertical, .sMedium)
            .shelfPaper(text: String(localized: action.title))
        }
        .buttonStyle(.plain)
        .accessibilityHint(Text(action.detail))
        .accessibilityIdentifier(action.accessibilityIdentifier)
    }
}
