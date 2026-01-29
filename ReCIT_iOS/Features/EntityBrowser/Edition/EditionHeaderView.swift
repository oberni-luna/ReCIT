//
//  EditionHeaderView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 16/01/2026.
//
import SwiftUI

struct EditionHeaderView: View {
    @Environment(\.colorScheme) var colorScheme

    let edition: Edition
//    @Binding var entityDestination: EntityDestination?

    var body: some View {
        VStack(alignment: .leading, spacing: .xSmall) {
            imageView
                    .frame(maxHeight: 256)
                    .shadow(color:.black.opacity(0.1), radius: 10)
                    .padding(.bottom, .sMedium)

            Text(edition.title)
                .font(.largeTitle)
                .foregroundStyle(.textDefault)
                .bold()
            if let subtitle = edition.subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.textDefault)
            }
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
        if let url = URL(string: edition.image ?? "") {
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

