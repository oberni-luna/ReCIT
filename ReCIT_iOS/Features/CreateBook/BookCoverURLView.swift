//
//  BookCoverURLView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 06/11/2026.
//

import SwiftUI

/// « Image depuis une URL » for a book's cover: the screen opens on a Google Images search for its
/// title and ISBN, under the word about bibliographic data, with the « ? » that explains them.
struct BookCoverURLView: View {
    private let searchedTitle: String
    private let isbn: String
    private let onUse: (Data, URL) -> Void

    /// - Parameters:
    ///   - searchedTitle: What the image search asks for, with the ISBN.
    ///   - isbn: Without separators.
    ///   - onUse: Handed the image chosen — its reduced JPEG, and the address it came from.
    init(
        searchedTitle: String,
        isbn: String,
        onUse: @escaping (Data, URL) -> Void
    ) {
        self.searchedTitle = searchedTitle
        self.isbn = isbn
        self.onUse = onUse
    }

    var body: some View {
        CoverURLView(onUse: onUse) {
            BibliographicDataNotice()

            CoverURLSearchSection(title: searchedTitle, isbn: isbn)
        }
        .footer(onceLoaded: "create_book.cover_url.check")
        .bibliographicDataHelpButton()
    }
}

#Preview {
    NavigationStack {
        BookCoverURLView(searchedTitle: "Les Furtifs", isbn: "9782370490742") { _, _ in }
    }
}
