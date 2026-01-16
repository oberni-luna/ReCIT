//
//  CellThumbnail.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 04/12/2025.
//

import SwiftUI

struct CellThumbnail: View {
    let imageUrl: String?
    let cornerRadius: DesignSystem.CornerRadius

    init(imageUrl: String?, cornerRadius: DesignSystem.CornerRadius = .medium) {
        self.imageUrl = imageUrl
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        Group {
            if let imageUrl {
                EditionImage(imageUrl: imageUrl, contentMode: .fill)
            } else {
                Color.surfaceDisable
            }
        }
        .frame(width: 48, height: 48)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius ?? .medium))
    }
}

