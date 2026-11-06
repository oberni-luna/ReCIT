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
    /// The rounding of the photo's corners, which the zoom starts from and comes back to.
    let cornerRadius: DesignSystem.CornerRadius

    @State private var isShowingFullScreen: Bool = false
    @Namespace private var transition: Namespace.ID

    func body(content: Content) -> some View {
        if let url {
            Button {
                isShowingFullScreen = true
            } label: {
                content
            }
            .buttonStyle(.plain)
            .accessibilityLabel("photo.action.enlarge")
            .matchedTransitionSource(id: url, in: transition) { source in
                source.clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            }
            .fullScreenCover(isPresented: $isShowingFullScreen) {
                FullScreenCoverView(url: url)
                    .navigationTransition(.zoom(sourceID: url, in: transition))
            }
        } else {
            content
        }
    }
}

extension View {
    /// Opens `url` in the Plein écran on a tap, zooming out of a view rounded by `cornerRadius`.
    func enlargeablePhoto(
        _ url: URL?,
        cornerRadius: DesignSystem.CornerRadius
    ) -> some View {
        modifier(EnlargeablePhotoModifier(url: url, cornerRadius: cornerRadius))
    }
}
