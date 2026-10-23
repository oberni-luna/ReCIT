//
//  AvatarThumbnail.swift
//  ReCIT_iOS
//
//  A reader's or a group's picture, wherever one is listed — the counterpart of `CellThumbnail`
//  for people and groups, which `CellThumbnail` keeps drawing for books and authors.
//
//  The photo is laid over the fallback, as in Figma: the initials or the `person.2` glyph show
//  while it loads, stay when there is none, and come back when it fails — `CachedAsyncImage`
//  draws nothing at all after a failure, which used to leave a bare grey square (PRD 0019, Q21).
//  The placeholder is `Color.clear` rather than a spinner: clear, so the fallback shows through;
//  and flexible, so the loader measures the whole frame and asks for an image of that size.
//
//  Decorative to VoiceOver: every place that shows an avatar names the reader or the group next
//  to it, and initials read out before the name would only say it twice, badly.
//

import SwiftUI

struct AvatarThumbnail: View {
    let kind: AvatarKind
    let imageUrl: String?
    let side: CGFloat
    /// The ground of the fallback; see `AvatarFallbackView.fill`.
    let fallbackFill: DesignSystem.Color

    init(
        _ kind: AvatarKind,
        imageUrl: String?,
        side: CGFloat,
        fallbackFill: DesignSystem.Color = .backgroundTinted
    ) {
        self.kind = kind
        self.imageUrl = imageUrl
        self.side = side
        self.fallbackFill = fallbackFill
    }

    init(
        _ kind: AvatarKind,
        imageUrl: String?,
        size: ThumbnailSize = .small
    ) {
        self.init(
            kind,
            imageUrl: imageUrl,
            side: size.sizeInPt
        )
    }

    private var url: URL? {
        imageUrl.flatMap { URL(string: $0) }
    }

    var body: some View {
        ZStack {
            AvatarFallbackView(
                kind: kind,
                side: side,
                fill: fallbackFill
            )

            if let url {
                CachedAsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.clear
                }
            }
        }
        .frame(width: side, height: side)
        .clipShape(RoundedRectangle(cornerRadius: kind.isRound ? .full : .medium))
        .thumbnailShadow()
        .accessibilityHidden(true)
    }
}

#Preview {
    VStack(spacing: .medium) {
        HStack(spacing: .medium) {
            AvatarThumbnail(.reader(username: "olivier_berni"), imageUrl: nil, size: .medium)
            AvatarThumbnail(.group, imageUrl: nil, size: .medium)
            AvatarThumbnail(.reader(username: "Léa"), imageUrl: nil, side: 44)
            AvatarThumbnail(.group, imageUrl: nil, side: 44)
        }
        HStack(spacing: .medium) {
            AvatarThumbnail(.reader(username: "JeanLuc"), imageUrl: nil, side: 32)
            AvatarThumbnail(.group, imageUrl: nil, side: 32)
            AvatarThumbnail(.reader(username: "Aïcha"), imageUrl: "https://inventaire.io/img/broken", size: .small)
            AvatarThumbnail(.group, imageUrl: nil, size: .large)
        }
    }
    .padding()
}
