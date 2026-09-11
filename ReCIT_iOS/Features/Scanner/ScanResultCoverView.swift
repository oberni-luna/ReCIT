//
//  ScanResultCoverView.swift
//  ReCIT_iOS
//
//  The scanned book’s cover in the scanner’s result row. Not `CellThumbnail`: that one lands
//  on a light list surface at a 3:4 ratio, this one is a 48×75 paperback (the design’s
//  `Livre`) sitting on a camera feed, so its backing is a hole in the scrim rather than a
//  design-system card. See PRD 0005.
//

import SwiftUI

struct ScanResultCoverView: View {
    /// Straight from the design: 48×75, a shade taller than the lists’ 3:4 covers.
    private static let width: CGFloat = 48
    private static let height: CGFloat = 75

    let imageUrl: String?

    var body: some View {
        ZStack {
            ScanOverlayPalette.coverBacking

            if let imageUrl, let url = URL(string: imageUrl) {
                CachedAsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ProgressView()
                        .tint(ScanOverlayPalette.ink)
                }
            }
        }
        .frame(width: ScanResultCoverView.width, height: ScanResultCoverView.height)
        .clipShape(.rect(cornerRadius: DesignSystem.CornerRadius.minimal.rawValue))
        .shadow(.light)
    }
}
