//
//  EditionDifferencesSection.swift
//  ReCIT_iOS
//
//  « Ce qui diffère » between the two editions of a pair, one `Form / Labeled Value` per
//  property — « 542  ·  — » —, and « Pareil : … » for the rest under it. PRD 0028.
//

import SwiftUI

struct EditionDifferencesSection: View {
    let comparison: EditionComparison

    var body: some View {
        Section {
            if comparison.differences.isEmpty {
                Text("duplicates.review.no_difference")
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundSecondary)
            } else {
                ForEach(comparison.differences, id: \.property) { row in
                    Text(Self.values(of: row))
                        .textStyle(.content300)
                        .foregroundStyle(.foregroundDefault)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .withLabel(label: Self.label(of: row.property))
                }
            }
        } header: {
            Text("duplicates.review.differences")
                .textStyle(.action200)
                .foregroundStyle(.foregroundSecondary)
        } footer: {
            VStack(alignment: .leading, spacing: .small) {
                if comparison.sameProperties.isEmpty == false {
                    Text("duplicates.review.same \(comparison.sameProperties.map(Self.inlineName).formatted(.list(type: .and)))")
                }
                Text("duplicates.review.public_note")
            }
            .textStyle(.footnote200)
            .foregroundStyle(.foregroundSecondary)
        }
    }

    /// « « Tome 1 »  ·  « Tome 1 bis » », a missing value as « — ».
    static func values(of row: EditionComparison.Row) -> String {
        [row.first, row.second]
            .map { value in
                guard let value else { return "—" }
                switch row.property {
                case .title:
                    return String(localized: "duplicates.review.quoted \(value)")
                case .cover:
                    return value == "yes" ? String(localized: "duplicates.cover.yes") : String(localized: "duplicates.cover.no")
                default:
                    return value
                }
            }
            .joined(separator: "  ·  ")
    }

    static func label(of property: EditionComparison.Property) -> String {
        switch property {
        case .title: String(localized: "duplicates.property.title")
        case .isbn: String(localized: "duplicates.property.isbn")
        case .publisher: String(localized: "duplicates.property.publisher")
        case .publicationDate: String(localized: "duplicates.property.publication_date")
        case .pages: String(localized: "duplicates.property.pages")
        case .cover: String(localized: "duplicates.property.cover")
        case .language: String(localized: "duplicates.property.language")
        case .work: String(localized: "duplicates.property.work")
        }
    }

    /// The property's name inside a sentence — « éditeur », not « Éditeur ».
    static func inlineName(of property: EditionComparison.Property) -> String {
        switch property {
        case .title: String(localized: "duplicates.property_inline.title")
        case .isbn: String(localized: "duplicates.property_inline.isbn")
        case .publisher: String(localized: "duplicates.property_inline.publisher")
        case .publicationDate: String(localized: "duplicates.property_inline.publication_date")
        case .pages: String(localized: "duplicates.property_inline.pages")
        case .cover: String(localized: "duplicates.property_inline.cover")
        case .language: String(localized: "duplicates.property_inline.language")
        case .work: String(localized: "duplicates.property_inline.work")
        }
    }
}
