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
    let size: CGFloat

    init(imageUrl: String?, cornerRadius: DesignSystem.CornerRadius = .medium, size:CGFloat = 36) {
        self.imageUrl = imageUrl
        self.cornerRadius = cornerRadius
        self.size = size
    }

    var body: some View {
        Group {
            if let urlString = imageUrl?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                let url = URL(string: urlString) {
                CachedAsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ProgressView()
                }
            } else {
                Color.surfaceDisable
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .shadow(color: .black.opacity(0.1), radius: 2)
    }
}

