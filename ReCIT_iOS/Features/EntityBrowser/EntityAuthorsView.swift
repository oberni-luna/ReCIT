//
//  EditionAuthorsView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 25/01/2026.
//

import SwiftUI

struct EntityAuthorsView: View {
    @Environment(\.colorScheme) var colorScheme

    let authors: [Author]
    @Binding var entityDestination: NavigationDestination?

    var body: some View {
        if authors.count == 1, let author = authors.first {
            Button {
                entityDestination = NavigationDestination.author(uri: author.uri)
            } label: {
                HStack(alignment: .center, spacing: .small){
                    Group {
                        CellThumbnail(imageUrl: author.image, cornerRadius: .full)

                        Text(author.name)
                            .font(.headline)
                            .multilineTextAlignment(.leading)

                        Spacer()

                        Image(.chevronRight)
                    }
                }
                .foregroundStyle(.textDefault)
            }
        } else {
            ScrollView(.horizontal) {
                HStack(spacing: .sMedium) {
                    ForEach(authors) { author in
                        Button {
                            entityDestination = NavigationDestination.author(uri: author.uri)
                        } label: {
                            HStack(alignment: .center, spacing: .small){
                                Group {
                                    CellThumbnail(imageUrl: author.image, cornerRadius: .full, size: 36)

                                    Text(author.name)
                                        .font(.headline)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                        .fixedSize(horizontal: false, vertical: true)

                                    Image(.chevronRight)
                                        .padding(.trailing, .small)
                                }
                            }
                        }
                        .frame(maxWidth: 200)
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

