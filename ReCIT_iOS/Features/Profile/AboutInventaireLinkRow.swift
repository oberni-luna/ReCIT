//
//  AboutInventaireLinkRow.swift
//  ReCIT_iOS
//
//  One row of « Aller plus loin »: the page's name in the tinted action style, and an arrow
//  pointing out of the app, since the row leaves it for Safari. The whole row is the target.
//

import SwiftUI

struct AboutInventaireLinkRow: View {
    let title: LocalizedStringKey
    let destination: URL

    var body: some View {
        Link(destination: destination) {
            HStack(spacing: .small) {
                Text(title)
                    .textStyle(.action300)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "arrow.up.right")
                    .accessibilityHidden(true)
            }
            .foregroundStyle(.foregroundTinted)
            .padding(.vertical, .sMedium)
            .padding(.horizontal, .medium)
            .contentShape(.rect)
        }
    }
}
