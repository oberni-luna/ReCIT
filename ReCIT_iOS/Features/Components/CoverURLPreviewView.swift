//
//  CoverURLPreviewView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 06/11/2026.
//

import SwiftUI

/// The image the address points at, 120 × 180, and a line under it. `Form / Image Preview`
/// (`716:615`) in the Figma file.
struct CoverURLPreviewView: View {
    let preview: CoverURLPreview

    var body: some View {
        VStack(spacing: .small) {
            frame
                .frame(width: 120, height: 180)
                .clipShape(.rect(cornerRadius: DesignSystem.CornerRadius.medium))

            caption
                .textStyle(.caption200)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, .xxSmall)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var frame: some View {
        switch preview {
        case .empty:
            Image(systemName: "photo")
                .foregroundStyle(.foregroundSecondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.backgroundSecondary)
                .overlay {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                        .strokeBorder(
                            DesignSystem.Color.borderDefault.color,
                            style: .init(lineWidth: 1, dash: [4, 4])
                        )
                }
                .accessibilityHidden(true)
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.backgroundSecondary)
        case .loaded(let jpeg, _, _):
            if let image = UIImage(data: jpeg) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
        case .failed:
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(.foregroundError)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.backgroundError)
                .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private var caption: some View {
        switch preview {
        case .empty, .loading:
            Text("create_book.cover_url.preview_placeholder")
                .foregroundStyle(.foregroundSecondary)
        case let .loaded(_, width, height):
            Text("create_book.cover_url.dimensions \(width) \(height)")
                .foregroundStyle(.foregroundSecondary)
        case .failed:
            Text("create_book.cover_url.failed")
                .foregroundStyle(.foregroundError)
        }
    }
}

#Preview("Empty") {
    CoverURLPreviewView(preview: .empty)
}

#Preview("Failed") {
    CoverURLPreviewView(preview: .failed)
}
