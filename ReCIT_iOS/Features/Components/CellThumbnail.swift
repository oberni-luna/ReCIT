//
//  CellThumbnail.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 04/12/2025.
//

import SwiftUI

enum ThumbnailSize {
    case xsmall, small, medium, large

    /// The thumbnail's width. The height follows from the shape.
    var sizeInPt: CGFloat {
        switch self {
        case .xsmall: return 24
        case .small: return 36
        case .medium: return 48
        case .large: return 64
        }
    }
}

/// A thumbnail is square when it stands for a person — an avatar or an author, usually under a
/// `.full` corner radius — and 3:4 portrait when it stands for a book, because that is the shape
/// a cover actually has. Width is what `ThumbnailSize` fixes; portrait grows downwards from it.
enum ThumbnailShape {
    case square, portrait

    func height(forWidth width: CGFloat) -> CGFloat {
        switch self {
        case .square: return width
        case .portrait: return (width * 4 / 3).rounded()
        }
    }
}

struct CellThumbnail: View {
    let imageUrl: String?
    let cornerRadius: DesignSystem.CornerRadius
    let width: CGFloat
    let height: CGFloat

    init(
        imageUrl: String?,
        cornerRadius: DesignSystem.CornerRadius = .medium,
        size: ThumbnailSize = .small,
        shape: ThumbnailShape = .square
    ) {
        self.imageUrl = imageUrl
        self.cornerRadius = cornerRadius
        self.width = size.sizeInPt
        self.height = shape.height(forWidth: size.sizeInPt)
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
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .shadow(color: .black.opacity(0.1), radius: 2)
    }
}
