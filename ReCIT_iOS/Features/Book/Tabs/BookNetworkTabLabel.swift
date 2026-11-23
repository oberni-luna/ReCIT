//
//  BookNetworkTabLabel.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 22/11/2026.
//

import SwiftData
import SwiftUI

/// « Dans le réseau • 3 »: how many copies and lists my network holds of the book, the count Dans
/// le réseau's page lists. « Dans le réseau » alone when it holds none.
struct BookNetworkTabLabel: View {
    private let edition: Edition
    private let myUserId: String?

    init(
        edition: Edition,
        myUserId: String?
    ) {
        self.edition = edition
        self.myUserId = myUserId
    }

    var body: some View {
        BookListEntriesReader(workUris: edition.workUris, myUserId: myUserId) { entries in
            let count: Int = BookNetworkHoldings(copies: edition.items, lists: entries, myUserId: myUserId).count
            if count > 0 {
                Text("book.tab.network \(count)")
                    .accessibilityLabel(Text("book.tab.network.accessibility \(count)"))
            } else {
                Text("book.tab.network")
            }
        }
    }
}

#Preview {
    BookNetworkTabLabel(
        edition: .init(uri: "isbn:9782070360024", title: "L'Étranger", lang: "fr", authorNames: []),
        myUserId: "me"
    )
    .modelContainer(
        for: [Edition.self, EntityList.self, EntityListItem.self, User.self],
        inMemory: true
    )
}
