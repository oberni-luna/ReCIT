//
//  ExternalLinkRow.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 07/11/2026.
//

import SwiftUI

/// A row leaving the app for a site, opened in Safari: the site's logo, what it is for, and an
/// arrow pointing out. The logo sits in a column as wide as a friend's avatar, so the title lines
/// up with the names of the rows above it. Figma `Cell / External Link`.
struct ExternalLinkRow: View {
    private let title: LocalizedStringKey
    private let subtitle: LocalizedStringKey
    private let logo: ImageResource
    private let destination: URL

    init(
        _ title: LocalizedStringKey,
        subtitle: LocalizedStringKey,
        logo: ImageResource,
        destination: URL
    ) {
        self.title = title
        self.subtitle = subtitle
        self.logo = logo
        self.destination = destination
    }

    var body: some View {
        Link(destination: destination) {
            HStack(spacing: .small) {
                ExternalLinkLogo(logo)
                    .frame(width: ThumbnailSize.small.sizeInPt)

                VStack(alignment: .leading, spacing: .xxSmall) {
                    Text(title)
                        .textStyle(.content400Bold)
                        .foregroundStyle(.foregroundDefault)

                    Text(subtitle)
                        .textStyle(.footnote200)
                        .foregroundStyle(.foregroundSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)

                Image(systemName: "arrow.up.right")
                    .foregroundStyle(.foregroundSecondary)
                    .accessibilityHidden(true)
            }
            .contentShape(.rect)
        }
    }
}

#Preview {
    List {
        ExternalLinkRow(
            "list.where_to_find.recyclivre.title",
            subtitle: "list.where_to_find.recyclivre.subtitle",
            logo: .bookshopRecyclivre,
            destination: .documentsDirectory
        )
        ExternalLinkRow(
            "list.where_to_find.chez_mon_libraire.title",
            subtitle: "list.where_to_find.chez_mon_libraire.subtitle",
            logo: .bookshopChezMonLibraire,
            destination: .documentsDirectory
        )
    }
}
