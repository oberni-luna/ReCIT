//
//  InventaireNoticeLink.swift
//  ReCIT_iOS
//
//  A link written on the inventaire.io paper tag: underlined, in the paper's own green, opening
//  the page in Safari. Borderless, so that inside a `List` row only the words answer a tap —
//  a plain `Link` there would turn the whole tag into one target.
//

import SwiftUI

struct InventaireNoticeLink: View {
    let title: LocalizedStringKey
    let destination: URL

    var body: some View {
        Link(destination: destination) {
            Text(title)
                .textStyle(.action300)
                .underline()
                .foregroundStyle(ShelfPalette.labelLink)
        }
        .buttonStyle(.borderless)
    }
}
