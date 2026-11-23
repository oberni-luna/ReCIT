//
//  BookHeaderBackdrop.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 22/11/2026.
//

import SwiftUI

/// What the Fiche livre's header stands on. At rest, its cover blurred, from the top of the screen
/// down to the tabs, fading as the header folds. Once the page passes under the folded header, the
/// bars' own material, stopping on a hairline as a navigation bar does.
struct BookHeaderBackdrop: View {
    private let imageUrl: String?
    /// 0 at rest, 1 once folded.
    private let progress: CGFloat
    private let isContentUnder: Bool

    init(
        imageUrl: String?,
        progress: CGFloat,
        isContentUnder: Bool
    ) {
        self.imageUrl = imageUrl
        self.progress = progress
        self.isContentUnder = isContentUnder
    }

    private var url: URL? {
        imageUrl.flatMap { URL(string: $0) }
    }

    var body: some View {
        ZStack {
            if let url {
                Color.clear
                    .overlay {
                        CachedAsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Color.clear
                        }
                    }
                    .clipped()
                    .blur(radius: 80)
                    .opacity(0.2 * (1 - progress))
            }

            BarBackdrop()
                .opacity(isContentUnder ? 1 : 0)
                .animation(.easeOut(duration: 0.15), value: isContentUnder)
        }
        .ignoresSafeArea(edges: .top)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

#Preview {
    Text(verbatim: "Le Comte de Monte-Cristo")
        .textStyle(.title200)
        .padding(.vertical, .xxLarge)
        .frame(maxWidth: .infinity)
        .background {
            BookHeaderBackdrop(
                imageUrl: "https://inventaire.io/img/entities/9f25f75dba901ddb9817c3e4bf001d861530a3e7",
                progress: 0,
                isContentUnder: false
            )
        }
}
