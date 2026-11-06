//
//  EnlargeablePhotoModifier.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 06/11/2026.
//

import SwiftUI

/// A reader's, a group's or an author's photo that opens in the Plein écran on a tap. Without a
/// photo, the view is left as it is: nothing to open, nothing for VoiceOver to press.
struct EnlargeablePhotoModifier: ViewModifier {
    /// How the Plein écran comes on screen.
    enum Opening {
        /// Slides up over the screen, and closes on a swipe down of its own. For a photo laid over
        /// a UIKit view, which vanishes once it is made a transition's source.
        case slideUp
        /// Zooms out of the photo, whose corners have this rounding, and back into it.
        case zoom(from: DesignSystem.CornerRadius)
    }

    let url: URL?
    let opening: Opening

    @State private var isShowingFullScreen: Bool = false
    @State private var sourceSize: CGSize = .zero
    @Namespace private var transition: Namespace.ID

    func body(content: Content) -> some View {
        if let url {
            source(button(content), for: url)
                .fullScreenCover(isPresented: $isShowingFullScreen) {
                    fullScreen(url)
                }
        } else {
            content
        }
    }

    private func button(_ content: Content) -> some View {
        Button {
            isShowingFullScreen = true
        } label: {
            content
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("photo.action.enlarge")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction {
            isShowingFullScreen = true
        }
    }

    @ViewBuilder
    private func source(
        _ button: some View,
        for url: URL
    ) -> some View {
        switch opening {
        case .slideUp:
            button
        case let .zoom(cornerRadius):
            button
                .onGeometryChange(for: CGSize.self) { $0.size } action: { sourceSize = $0 }
                .matchedTransitionSource(id: url, in: transition) { source in
                    source.clipShape(.rect(cornerRadius: sourceCornerRadius(cornerRadius)))
                }
        }
    }

    private func sourceCornerRadius(_ cornerRadius: DesignSystem.CornerRadius) -> CGFloat {
        min(cornerRadius.rawValue, min(sourceSize.width, sourceSize.height) / 2)
    }

    @ViewBuilder
    private func fullScreen(_ url: URL) -> some View {
        switch opening {
        case .slideUp:
            FullScreenCoverView(url: url)
                .closingOnSwipeDown()
        case .zoom:
            FullScreenCoverView(url: url)
                .navigationTransition(.zoom(sourceID: url, in: transition))
        }
    }
}

extension View {
    /// Opens `url` in the Plein écran on a tap, the way `opening` says.
    func enlargeablePhoto(
        _ url: URL?,
        opening: EnlargeablePhotoModifier.Opening = .slideUp
    ) -> some View {
        modifier(EnlargeablePhotoModifier(url: url, opening: opening))
    }
}
