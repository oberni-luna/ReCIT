//
//  AboutInventaireShelfTag.swift
//  ReCIT_iOS
//
//  The paper tag under the À propos plank: inventaire.io's logo and its name, on the same paper
//  an étagère's name is written on (`ShelfPaperModifier`), at the same padding as
//  `ShelfLabelView`. The name is not translated — it is a name.
//

import SwiftUI

struct AboutInventaireShelfTag: View {
    private let name: String = "inventaire.io"

    var body: some View {
        HStack(spacing: .xSmall) {
            Image(.inventaireIo)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .clipShape(.rect(cornerRadius: .minimal))

            Text(verbatim: name)
                .textStyle(.content300)
                .foregroundStyle(ShelfPalette.labelInk)
                .lineLimit(1)
        }
        .padding(.horizontal, .small)
        .padding(.vertical, .xSmall)
        .shelfPaper(text: name)
    }
}

#Preview {
    AboutInventaireShelfTag()
        .padding()
}
