//
//  BibliographicDataHelpButton.swift
//  ReCIT_iOS
//
//  The « ? » at the trailing end of every navigation bar of the book creation, which opens the
//  help about bibliographic data. `Chrome / Sheet Nav Bar`'s `Show trailing` in the Figma file.
//
//  See PRD 0026.
//

import SwiftUI

struct BibliographicDataHelpButton: View {
    @Environment(\.showBibliographicDataHelp) private var showHelp

    var body: some View {
        Button("create_book.notice.title", systemImage: "questionmark.circle") {
            showHelp()
        }
        .accessibilityIdentifier("e2e.createBook.help")
    }
}

extension View {
    /// Puts the « ? » in the navigation bar of a screen of the book creation.
    func bibliographicDataHelpButton() -> some View {
        toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                BibliographicDataHelpButton()
            }
        }
    }
}
