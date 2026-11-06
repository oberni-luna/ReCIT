//
//  CoverURLSearchSection.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 06/11/2026.
//

import SwiftUI

/// The head of « Image depuis une URL » for a book's cover: a Google Images search for the work's
/// title and the ISBN, which opens in Safari.
struct CoverURLSearchSection: View {
    let title: String
    /// Without separators.
    let isbn: String

    @Environment(\.openURL) private var openURL: OpenURLAction

    var body: some View {
        Section {
            Button {
                if let url = CoverAddress.googleImagesURL(title: title, isbn: isbn) {
                    openURL(url)
                }
            } label: {
                Label("create_book.cover_url.search", systemImage: "magnifyingglass")
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundTinted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(AccessibilityID.search)
        } header: {
            CreateBookSectionHeader("create_book.cover_url.find")
        } footer: {
            CreateBookSectionFooter("create_book.cover_url.find_help")
        }
    }
}

private extension CoverURLSearchSection {
    enum AccessibilityID {
        static let search: String = "e2e.createBook.coverUrl.search"
    }
}

#Preview {
    DesignSystem.Form {
        CoverURLSearchSection(title: "Les Furtifs", isbn: "9782370490742")
    }
}
