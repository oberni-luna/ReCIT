//
//  CellThumbnail.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 04/12/2025.
//

import SwiftUI

enum ThumbnailSize {
    case xsmall, small, medium, large

    var sizeInPt: CGFloat {
        switch self {
        case .xsmall: return 24
        case .small: return 36
        case .medium: return 48
        case .large: return 64
        }
    }
}

struct CellThumbnail: View {
    let imageUrl: String?
    let cornerRadius: DesignSystem.CornerRadius
    let size: CGFloat

    init(imageUrl: String?, cornerRadius: DesignSystem.CornerRadius = .medium, size:ThumbnailSize = .small) {
        self.imageUrl = imageUrl
        self.cornerRadius = cornerRadius
        self.size = size.sizeInPt
    }

    var body: some View {
        ZStack {
            DesignSystem.Color.backgroundDisable.color
            if let imageUrl, let url = URL(string: imageUrl) {
                CachedAsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ProgressView()
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .shadow(color: .black.opacity(0.1), radius: 2)
    }
}

