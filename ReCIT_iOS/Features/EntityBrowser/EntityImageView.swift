//
//  EntityHeaderView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 24/01/2026.
//

import SwiftUI
import SwiftData

struct EntityImageView<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme

    let imageUrl: String?
    let content: () -> Content

    @State private var isShowingFullScreen: Bool = false
    @Namespace private var coverTransition

    var body: some View {
        VStack(alignment: .leading, spacing: .xSmall) {
            tappableImageView
                .frame(maxWidth:.infinity)
                .frame(height: 256)
                .shadow(color:.black.opacity(0.1), radius: 10)
                .padding(.bottom, .sMedium)

            content()
        }
        .background(alignment: .bottom) {
            imageView
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea(.all)
                .blur(radius: 80)
                .opacity(colorScheme == .dark ? 0.2 : 0.2)
                .accessibilityHidden(true)
        }
    }

    /// The cover opens full screen, zooming out of where it sits. Only the cover itself is the
    /// button — the blurred copy behind the header is decoration.
    @ViewBuilder
    var tappableImageView: some View {
        if let url = URL(string: imageUrl ?? "") {
            Button {
                isShowingFullScreen = true
            } label: {
                imageView
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Agrandir la couverture")
            .matchedTransitionSource(id: url, in: coverTransition)
            .accessibilityIdentifier("e2e.entityCover")
            .fullScreenCover(isPresented: $isShowingFullScreen) {
                FullScreenCoverView(url: url)
                    .navigationTransition(.zoom(sourceID: url, in: coverTransition))
            }
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    var imageView: some View {
        if let url = URL(string: imageUrl ?? "") {
            CachedAsyncImage(url: url) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 256)
                    .cornerRadius(.minimal)
            } placeholder: {
                Color.clear
                    .cornerRadius(.minimal)
            }
        } else {
            EmptyView()
        }
    }
}

