//
//  InventaireNoticeTag.swift
//  ReCIT_iOS
//
//  The paper tag at the top of the Profil that says where the books go: the app is plugged
//  into inventaire.io, and every book added here enriches its open data. The same paper as the
//  empty shelf and the empty Lists tab, with one difference — this one can be put away, by the
//  cross beside its title, since it is not an empty state and would otherwise stay for ever.
//
//  Its links are inked with `ShelfPalette.labelLink`, not `foregroundTinted`: the paper stays
//  white in dark mode, where the tinted token turns a pale green that white paper swallows.
//

import SwiftUI

struct InventaireNoticeTag: View {
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: .small) {
            HStack(spacing: .small) {
                Label {
                    Text("profile.inventaire.title")
                        .textStyle(.content400Bold)
                } icon: {
                    Image(systemName: "books.vertical")
                }
                .accessibilityAddTraits(.isHeader)

                Spacer(minLength: .zero)

                Button("profile.inventaire.dismiss", systemImage: "xmark.circle", action: onDismiss)
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderless)
                    .foregroundStyle(ShelfPalette.labelInk)
                    .accessibilityIdentifier("e2e.profile.inventaire.dismiss")
            }

            Text("profile.inventaire.commons")
                .textStyle(.content300)
            InventaireNoticeLink(title: "profile.inventaire.commons.link", destination: Constant.inventaireURL)

            Text("profile.inventaire.data")
                .textStyle(.content300)
            InventaireNoticeLink(title: "profile.inventaire.data.link", destination: Constant.dataURL)
        }
        .foregroundStyle(ShelfPalette.labelInk)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, .medium)
        .padding(.vertical, .sMedium)
        .shelfPaper(text: String(localized: "profile.inventaire.title"))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("e2e.profile.inventaire")
    }
}

private extension InventaireNoticeTag {
    enum Constant {
        static let inventaireURL: URL = .init(string: "https://inventaire.io")!
        static let dataURL: URL = .init(string: "https://data.inventaire.io")!
    }
}
