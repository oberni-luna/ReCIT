//
//  EditionView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 12/12/2025.
//
import SwiftData
import SwiftUI

struct EditionView: View {
    let edition: Edition

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .xSmall) {

                EditionImage(imageUrl: edition.image, contentMode: .fit)
                    .frame(maxHeight: 256)
                    .clipped()

                Text(edition.title)
                    .font(.largeTitle)
                    .bold()
                if let subtitle = edition.subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                }

                Text(.init(edition.works.map { "**\($0.title)** : \($0.authors.map {$0.name}.joined(separator: ","))" }.joined(separator: "\n")))


            }
            .padding()
        }
    }
}

#Preview {
    
}
