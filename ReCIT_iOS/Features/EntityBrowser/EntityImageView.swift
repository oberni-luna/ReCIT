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

    var body: some View {
        VStack(alignment: .leading, spacing: .xSmall) {
            imageView
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

    @ViewBuilder
    var imageView: some View {
        if let url = URL(string: imageUrl ?? "") {
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(.minimal)
            } placeholder: {
                ProgressView()
            }
        } else {
            EmptyView()
        }
    }
}

