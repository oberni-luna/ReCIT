//
//  BibliographicDataNotice.swift
//  ReCIT_iOS
//
//  « Données bibliographiques » — three lines at the head of every screen of the book creation:
//  where works, editions and authors come from, and that what is typed here becomes public,
//  under CC0, editable by anyone. `Form / Notice` (`722:595`) in the Figma file; a summary of
//  inventaire.io's own « À propos des données bibliographiques ».
//
//  Shown until it is put away, and then put away everywhere and for good, as inventaire.io does
//  with its own: a contributor who has read it once does not need it on every book. The « ? »
//  of the navigation bar opens the whole of it whenever it is wanted again.
//
//  A whole section, so a screen places it in one line and it takes its own row's insets and
//  background off — it is a card of its own, not a row of a card.
//
//  See PRD 0021.
//

import SwiftUI

struct BibliographicDataNotice: View {
    @AppStorage("createBook.bibliographicNotice.dismissed") private var isDismissed: Bool = false

    var body: some View {
        if isDismissed == false {
            Section {
                BibliographicDataNoticeCard {
                    isDismissed = true
                }
                .listRowInsets(.init())
                .listRowBackground(Color.clear)
            }
        }
    }
}

private struct BibliographicDataNoticeCard: View {
    @Environment(\.showBibliographicDataHelp) private var showHelp

    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: .sMedium) {
            Image(systemName: "questionmark.circle")
                .foregroundStyle(.foregroundTinted)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: .xSmall) {
                Text("create_book.notice.title")
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundDefault)

                Text("create_book.notice.body")
                    .textStyle(.footnote200)
                    .foregroundStyle(.foregroundDefault)

                Button("create_book.notice.learn_more") {
                    showHelp()
                }
                .buttonStyle(.plain)
                .textStyle(.footnote200Bold)
                .foregroundStyle(.foregroundTinted)
                .accessibilityIdentifier("e2e.createBook.notice.learnMore")
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button("action.close", systemImage: "xmark", action: onDismiss)
                .labelStyle(.iconOnly)
                .buttonStyle(.plain)
                .textStyle(.footnote200Bold)
                .foregroundStyle(.foregroundSecondary)
                .accessibilityIdentifier("e2e.createBook.notice.close")
        }
        .padding(.vertical, .sMedium)
        .padding(.leading, .medium)
        .padding(.trailing, .sMedium)
        .background(.backgroundTinted)
        .clipShape(.rect(cornerRadius: DesignSystem.CornerRadius.medium))
    }
}
