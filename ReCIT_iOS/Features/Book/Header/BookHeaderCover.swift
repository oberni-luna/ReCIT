//
//  BookHeaderCover.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 22/11/2026.
//

import SwiftUI

/// The book's cover in the Fiche livre's header, at whatever height the fold leaves it: large and
/// centred at rest, a book row's size once folded. A tap opens it in the Plein écran, sliding up as
/// a reader's photo does over the pager — a zoom source laid over it vanishes.
struct BookHeaderCover: View {
    private let imageUrl: String?
    private let height: CGFloat

    init(
        _ imageUrl: String?,
        height: CGFloat
    ) {
        self.imageUrl = imageUrl
        self.height = height
    }

    private var url: URL? {
        imageUrl.flatMap { URL(string: $0) }
    }

    var body: some View {
        cover
            .frame(height: height)
            .clipShape(.rect(cornerRadius: .minimal))
            .shadow(.entityGlow)
            .enlargeablePhoto(url, accessibilityLabel: "cover.action.enlarge")
            .accessibilityIdentifier(AccessibilityID.cover)
    }

    @ViewBuilder
    private var cover: some View {
        if let url {
            CachedAsyncImage(url: url) { image in
                image
                    .resizable()
                    .scaledToFit()
            } placeholder: {
                BookHeaderCoverPlaceholder()
            }
        } else {
            BookHeaderCoverPlaceholder()
        }
    }
}

private extension BookHeaderCover {
    enum AccessibilityID {
        static let cover: String = "e2e.entityCover"
    }
}

#Preview("Cover") {
    BookHeaderCover("https://inventaire.io/img/entities/9f25f75dba901ddb9817c3e4bf001d861530a3e7", height: 256)
}

#Preview("No cover") {
    BookHeaderCover(nil, height: 256)
}
