//
//  EditionAuthorsView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 25/01/2026.
//

import SwiftUI
import SwiftData

struct EntityAuthorsView: View {
    @Environment(\.colorScheme) var colorScheme

    let authors: [Author]
    @Binding var entityDestination: NavigationDestination?

    var body: some View {
        if authors.count == 1, let author = authors.first {
            Button {
                entityDestination = NavigationDestination.author(uri: author.uri)
            } label: {
                NavigationLink(value: UUID()) {
                    HStack(alignment: .center, spacing: .small){
                        Group {
                            CellThumbnail(imageUrl: author.image, cornerRadius: .full)

                            Text(author.name)
                                .textStyle(.content400Bold)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .foregroundStyle(.foregroundDefault)
                }
            }
        } else {
            ScrollView(.horizontal) {
                HStack(spacing: .sMedium) {
                    ForEach(authors) { author in
                        Button {
                            entityDestination = NavigationDestination.author(uri: author.uri)
                        } label: {
                            NavigationLink(value: UUID()) {
                                HStack(alignment: .center, spacing: .small){
                                    Group {
                                        CellThumbnail(imageUrl: author.image, cornerRadius: .full, size: 36)
                                        
                                        Text(author.name)
                                            .textStyle(.content400Bold)
                                            .lineLimit(2)
                                            .multilineTextAlignment(.leading)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
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

