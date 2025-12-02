//
//  ImageTagView.swift
//  Trompet
//
//  Created by Jean-Daniel Boutin on 09/05/2025.
//

import SwiftUI

struct ImageTagView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let text: String

    init(text: String) {
        self.text = text
    }
    var body: some View {
        Text(text)
            .textStyle(.footnote100)
            .foregroundStyle(.textDefault)
            .padding(.all, .xSmall)
            .lineLimit(1)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: .minimal))
    }
}
