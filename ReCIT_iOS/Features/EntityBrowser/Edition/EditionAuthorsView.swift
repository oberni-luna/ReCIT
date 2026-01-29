//
//  EditionAuthorsView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 25/01/2026.
//

import SwiftUI

struct EditionAuthorsView: View {
    @Environment(\.colorScheme) var colorScheme

    let edition: Edition
    @Binding var entityDestination: EntityDestination?

    var body: some View {
        if edition.authors.count == 1, let author = edition.authors.first {
            Button {
                entityDestination = EntityDestination.author(uri: author.uri)
            } label: {
                HStack(alignment: .center, spacing: .xSmall){
                    Group {
                        CellThumbnail(imageUrl: author.image, cornerRadius: .full, size: 36)
                            .padding(.vertical, .small)

                        Text(author.name)
                            .font(.headline)
                            .multilineTextAlignment(.leading)

                        Spacer()

                        Image(.chevronRight)
                            .padding(.trailing, .small)
                    }
                }
                .foregroundStyle(.textDefault)
                .padding(.horizontal, .medium)
            }
        } else {
            ScrollView(.horizontal) {
                HStack(spacing: .sMedium) {
                    ForEach(edition.authors) { author in
                        Button {
                            entityDestination = EntityDestination.author(uri: author.uri)
                        } label: {
                            HStack(alignment: .center, spacing: .xSmall){
                                Group {
                                    CellThumbnail(imageUrl: author.image, cornerRadius: .full, size: 36)
                                        .padding(.vertical, .small)
                                        .padding(.leading, .small)

                                    Text(author.name)
                                        .font(.headline)
                                        .multilineTextAlignment(.leading)

                                    Spacer()

                                    Image(.chevronRight)
                                        .padding(.trailing, .small)
                                }
                            }
                            .foregroundStyle(.textDefault)
                            .frame(maxWidth: 200)
                            .background(.thickMaterial)
                            .cornerRadius(.rounded)
                        }
                    }
                }
                .padding(.horizontal, .medium)
            }
        }
    }
}

