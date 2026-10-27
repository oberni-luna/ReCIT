//
//  EditionCell.swift
//  ReCIT_iOS
//
//  One edition of a work, said so that it can be told apart from the others: its title, then
//  « publisher · collection · year », then its ISBN — or « Sans ISBN » — with an optional tag.
//  `Cell / Edition` (`767:4222`) in the Figma file.
//
//  `leading` is the variant: `.none` in the list of « Éditions », `.off` / `.on` in the duplicate
//  review, where a round check says which edition is kept.
//
//  See PRD 0028.
//

import SwiftUI

struct EditionCell: View {
    enum Leading {
        case none
        case off
        case on
    }

    let edition: Edition
    var leading: Leading = .none

    var body: some View {
        HStack(spacing: .sMedium) {
            if leading != .none {
                Image(systemName: leading == .on ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(leading == .on ? .foregroundTinted : .foregroundSecondary)
                    .accessibilityHidden(true)
            }

            CellThumbnail(imageUrl: edition.image)

            VStack(alignment: .leading, spacing: .xxSmall) {
                Text(edition.title)
                    .textStyle(.content400Bold)
                    .foregroundStyle(.foregroundDefault)

                if let details = EditionCell.details(of: edition) {
                    Text(details)
                        .textStyle(.content300)
                        .foregroundStyle(.foregroundSecondary)
                }

                isbnLine
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(leading == .on ? .isSelected : [])
    }

    @ViewBuilder
    private var isbnLine: some View {
        Group {
            if let isbn = edition.isbn {
                Text("edition.isbn \(isbn)")
            } else {
                Text("edition.no_isbn")
            }
        }
        .textStyle(.footnote200Bold)
        .foregroundStyle(.foregroundDefault)
    }

    /// « Gallimard · Folio classique · 1998 », with whatever of the three is known.
    static func details(of edition: Edition) -> String? {
        let parts: [String] = [edition.publisherName, edition.collectionName, edition.publicationYear]
            .compactMap { $0 }
            .filter { $0.isEmpty == false }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}
