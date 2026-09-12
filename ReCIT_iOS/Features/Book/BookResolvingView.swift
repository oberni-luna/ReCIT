//
//  BookResolvingView.swift
//  ReCIT_iOS
//
//  The book screen while it is still deciding which book it is.
//
//  A search result names a work, and picking the edition behind it costs a round trip —
//  ~750 ms, measured (ADR 0002, Move 3). Showing a bare spinner for that second would make
//  every tap on a result feel like it went nowhere, so the screen opens wearing the work's own
//  title and cover, which the search result already carried and which cost nothing to bring
//  along. Only the body is waiting.
//
//  It is deliberately the same `EntityHeaderView` the loaded screen uses, in the same list
//  section: when the edition lands, the header does not jump — it is already in place, and at
//  most its text changes.
//
//  See PRD 0014.
//

import SwiftUI

struct BookResolvingView: View {
    let placeholder: BookAnchor.Placeholder

    var body: some View {
        List {
            Section {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .listRowSeparator(.hidden)
            } header: {
                EntityHeaderView(
                    title: placeholder.title,
                    subtitle: nil,
                    imageUrl: placeholder.imageUrl
                )
            }
        }
        .applyListBackground()
        .accessibilityIdentifier("e2e.book.resolving")
    }
}

#Preview("Pendant la résolution") {
    NavigationStack {
        BookResolvingView(placeholder: .init(title: "Dune", imageUrl: nil))
            .navigationBarTitleDisplayMode(.inline)
    }
}
