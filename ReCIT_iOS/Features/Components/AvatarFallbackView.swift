//
//  AvatarFallbackView.swift
//  ReCIT_iOS
//
//  What an avatar shows when there is no picture, or the picture would not load — the
//  `Avatar · Repli` component of the Figma pass (Q20, Q21, Q21 bis): a reader's initials or the
//  `person.2` glyph, in `foregroundTinted`, on a `backgroundTinted` fill. Square and unclipped:
//  `AvatarThumbnail` lays the photo over it and gives both their shape.
//

import SwiftUI

struct AvatarFallbackView: View {
    let kind: AvatarKind
    let side: CGFloat
    /// The ground under the mark: tinted, except where the avatar sits on a tinted surface
    /// already — a group tile on the card of a group I administer (`Graph / Group`, Admin).
    var fill: DesignSystem.Color = .backgroundTinted

    private var metrics: AvatarMetrics {
        .init(side: side)
    }

    var body: some View {
        ZStack {
            fill.color

            if metrics.showsMark {
                switch kind {
                case .reader(let username):
                    // A fixed disc around a Dynamic Type font: the letters shrink to stay inside
                    // it rather than spill out at the largest sizes.
                    Text(verbatim: ReaderInitials.of(username))
                        .textStyle(metrics.usesLargeType ? .action300 : .action200)
                        .foregroundStyle(.foregroundTinted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.4)
                        .padding(.horizontal, .xSmall)
                case .group:
                    Image(systemName: "person.2")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.foregroundTinted)
                        .frame(width: metrics.glyphSide, height: metrics.glyphSide)
                }
            }
        }
        .frame(width: side, height: side)
    }
}
