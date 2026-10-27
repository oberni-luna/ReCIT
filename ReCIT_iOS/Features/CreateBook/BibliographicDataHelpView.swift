//
//  BibliographicDataHelpView.swift
//  ReCIT_iOS
//
//  « Données bibliographiques », in full: what they are, where they come from, what publishing
//  here means, and where to go further. Frame `V13` of « Nouveau livre v2 » in the Figma file,
//  opened as a sheet by the « ? » of any screen of the book creation.
//
//  The text summarises inventaire.io's own notice (`about_bibliographic_data.svelte` and
//  `bibliographic_data_settings.svelte` in inventaire-client), and the three links are the ones
//  it gives. « Voir mes contributions » needs to know who is asking, and is left out when that
//  is not known.
//
//  See PRD 0026.
//

import SwiftUI

struct BibliographicDataHelpView: View {
    @Environment(UserModel.self) private var userModel
    @Environment(\.dismiss) private var dismiss

    private var contributions: URL? {
        guard let username = userModel.myUser?.username else { return nil }
        return BibliographicDataLinks.contributions(username: username, baseUrl: Env.production.apiBaseUrl)
    }

    var body: some View {
        NavigationStack {
            DesignSystem.FormList {
                BibliographicDataHelpParagraph(
                    header: "create_book.help.what",
                    text: "create_book.help.what_body"
                )

                BibliographicDataHelpParagraph(
                    header: "create_book.help.from",
                    text: "create_book.help.from_body"
                )

                BibliographicDataHelpParagraph(
                    header: "create_book.help.publish",
                    text: "create_book.help.publish_body"
                )

                Section {
                    if let wiki = BibliographicDataLinks.wiki {
                        BibliographicDataHelpLink(title: "create_book.help.wiki", destination: wiki)
                    }

                    if let chat = BibliographicDataLinks.chat {
                        BibliographicDataHelpLink(title: "create_book.help.chat", destination: chat)
                    }

                    if let contributions {
                        BibliographicDataHelpLink(title: "create_book.help.contributions", destination: contributions)
                    }
                } header: {
                    CreateBookSectionHeader("create_book.help.further")
                }
            }
            .navigationTitle(String(localized: "create_book.notice.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action.close", systemImage: "xmark") {
                        dismiss()
                    }
                }
            }
        }
    }
}

/// A heading and a paragraph, set in the column rather than in a card: this is reading, not a
/// form. `Section Header` over `Note` (`101:236`) in the Figma file.
private struct BibliographicDataHelpParagraph: View {
    let header: LocalizedStringKey
    let text: LocalizedStringKey

    var body: some View {
        Section {
            Text(text)
                .textStyle(.content300)
                .foregroundStyle(.foregroundDefault)
                .listRowBackground(Color.clear)
        } header: {
            CreateBookSectionHeader(header)
        }
    }
}

/// One way further, as a tinted link row. `Form / Action Row` (`701:556`) with the `link`
/// glyph in the Figma file.
private struct BibliographicDataHelpLink: View {
    let title: LocalizedStringKey
    let destination: URL

    var body: some View {
        Link(destination: destination) {
            Label(title, systemImage: "link")
                .textStyle(.content300)
                .foregroundStyle(.foregroundTinted)
        }
    }
}
