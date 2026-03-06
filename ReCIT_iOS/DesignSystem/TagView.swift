//
//  TagView.swift
// DansMaPoche
//
//  Created by Quentin Noblet on 18/11/2024.
//

import SwiftUI

struct TagView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let text: String

    var body: some View {
        Text(text)
            .textStyle(.footnote200)
            .foregroundStyle(.foregroundSecondary)
            .padding(.all, .small)
            .lineLimit(1)
            .background {
                RoundedRectangle(cornerRadius: .medium)
            }
    }
}

private extension Constant {
    static let borderWidth: CGFloat = 1
}

#Preview {
    HStack {
        TagView(text: "Hello, World!")
        TagView(text: "SwiftUI")
    }
}
