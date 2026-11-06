//
//  EnlargeablePhotoModifier.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 06/11/2026.
//

import SwiftUI

/// A reader's or a group's photo that opens in the Plein écran, zooming out of where it sits, as
/// a book's cover does on the Fiche livre. Without a photo, the view is left as it is: nothing
/// to open, nothing for VoiceOver to press.
struct EnlargeablePhotoModifier: ViewModifier {
    let url: URL?
    /// The rounding of the photo's corners, which the zoom starts from and comes back to. `nil`
    /// opens the Plein écran without the zoom: a photo laid over a UIKit view — the friend's
    /// header, over the pages of `TabPager` — vanishes once it is made a transition's source.
    let zoomCornerRadius: DesignSystem.CornerRadius?

    @State private var isShowingFullScreen: Bool = false
    @Namespace private var transition: Namespace.ID

    func body(content: Content) -> some View {
        if let url {
            if let zoomCornerRadius {
                button(content)
                    .matchedTransitionSource(id: url, in: transition) { source in
                        source.clipShape(RoundedRectangle(cornerRadius: zoomCornerRadius))
                    }
                    .fullScreenCover(isPresented: $isShowingFullScreen) {
                        FullScreenCoverView(url: url)
                            .navigationTransition(.zoom(sourceID: url, in: transition))
                    }
            } else {
                button(content)
                    .fullScreenCover(isPresented: $isShowingFullScreen) {
                        FullScreenCoverView(url: url)
                    }
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
        .accessibilityLabel("photo.action.enlarge")
    }
}

extension View {
    /// Opens `url` in the Plein écran on a tap, zooming out of a view rounded by
    /// `zoomCornerRadius`, or sliding up over the screen when it is `nil`.
    func enlargeablePhoto(
        _ url: URL?,
        zoomingFrom zoomCornerRadius: DesignSystem.CornerRadius? = nil
    ) -> some View {
        modifier(EnlargeablePhotoModifier(url: url, zoomCornerRadius: zoomCornerRadius))
    }
}
