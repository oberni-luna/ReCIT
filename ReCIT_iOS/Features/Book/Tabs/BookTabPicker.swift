//
//  BookTabPicker.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 22/11/2026.
//

import SwiftData
import SwiftUI

/// Présentation | Mon exemplaire | Dans le réseau • 3, at the foot of the Fiche livre's header:
/// the lens capsules of a reader's profile, following the pager and picked up to slide across
/// the words.
struct BookTabPicker: View {
    private let pagePosition: CGFloat
    private let edition: Edition
    private let myUserId: String?

    @Binding private var selection: BookTab

    init(
        selection: Binding<BookTab>,
        pagePosition: CGFloat,
        edition: Edition,
        myUserId: String?
    ) {
        _selection = selection
        self.pagePosition = pagePosition
        self.edition = edition
        self.myUserId = myUserId
    }

    var body: some View {
        LensTabPicker(selection: $selection, pagePosition: pagePosition) { tab in
            label(for: tab)
                .accessibilityIdentifier(tab.accessibilityID)
        }
        .wordPadding(.small)
        .accessibilityLabel("book.tabs")
    }

    @ViewBuilder
    private func label(for tab: BookTab) -> some View {
        switch tab {
        case .presentation:
            Text("book.tab.presentation")
        case .myCopy:
            Text("book.tab.my_copy")
        case .network:
            BookNetworkTabLabel(edition: edition, myUserId: myUserId)
        }
    }
}

#Preview {
    @Previewable @State var tab: BookTab = .presentation

    BookTabPicker(
        selection: $tab,
        pagePosition: 0,
        edition: .init(uri: "isbn:9782070360024", title: "L'Étranger", lang: "fr", authorNames: []),
        myUserId: "me"
    )
    .modelContainer(
        for: [Edition.self, EntityList.self, EntityListItem.self, User.self],
        inMemory: true
    )
}
