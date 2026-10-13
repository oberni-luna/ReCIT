//
//  AboutInventaireView.swift
//  ReCIT_iOS
//
//  « À propos d'inventaire.io », pushed from the Profil: what the library behind the app is, said
//  once and plainly. An étagère carrying my latest books under an « inventaire.io » tag, the
//  sentence that ties the two together, the four things inventaire.io is, four pages to go
//  further, and the note that the app is independent of it.
//
//  On white (`backgroundDefault`), like the donation sheet: a page to read rather than a list to
//  act on, which is what the grouped grey of the other screens says.
//
//  It took over from the paper tag that used to sit under the account (feature 0026): the
//  commons and the open data it spoke of are two of the four rows here, and its two links are
//  two of the four below them.
//
//  See the Figma frame `P2 · À propos d'inventaire.io · Fond blanc` (`588:17876`).
//

import SwiftUI

struct AboutInventaireView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: .large) {
                AboutInventaireShelf()
                    .padding(.horizontal, .medium)

                VStack(spacing: .small) {
                    Text("about.headline")
                        .textStyle(.title200)
                        .foregroundStyle(.foregroundDefault)
                        .accessibilityAddTraits(.isHeader)
                    Text("about.tagline")
                        .textStyle(.content300)
                        .foregroundStyle(.foregroundSecondary)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, .large)

                VStack(spacing: .large) {
                    AboutInventaireValueRow(
                        systemImage: "book",
                        title: "about.value.commons.title",
                        detail: "about.value.commons.body"
                    )
                    AboutInventaireValueRow(
                        systemImage: "person",
                        title: "about.value.account.title",
                        detail: "about.value.account.body"
                    )
                    AboutInventaireValueRow(
                        systemImage: "point.3.connected.trianglepath.dotted",
                        title: "about.value.data.title",
                        detail: "about.value.data.body"
                    )
                    AboutInventaireValueRow(
                        systemImage: "hand.wave",
                        title: "about.value.software.title",
                        detail: "about.value.software.body"
                    )
                }
                .padding(.horizontal, .medium)

                AboutInventaireLinks()
                    .padding(.horizontal, .medium)

                VStack(spacing: .small) {
                    AppIconTile(size: 44)
                    Text("about.independence")
                        .textStyle(.footnote200)
                        .foregroundStyle(.foregroundSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, .xLarge)
            }
            .padding(.top, .small)
            .padding(.bottom, .large)
        }
        .background(.backgroundDefault)
        .navigationTitle("about.title")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("e2e.about")
    }
}

#Preview {
    NavigationStack {
        AboutInventaireView()
    }
}
