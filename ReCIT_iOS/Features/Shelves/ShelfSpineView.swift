//
//  ShelfSpineView.swift
//  ReCIT_iOS
//
//  One book standing spine-out on a shelf: a painted rectangle with the title set
//  vertically. Fetches the edition's page count lazily so its thickness (set by the
//  parent) can reflect the real book. See ADR 0003.
//

import SwiftUI
import SwiftData

struct ShelfSpineView: View {
    let item: InventoryItem
    let size: CGSize

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        PaintedBookView(edition: item.edition, size: size) { ink in
            Text(item.edition?.title ?? "")
                .textStyle(.footnote200Bold)
                .foregroundStyle(ink)
                .shadow(color: .black.opacity(0.45), radius: 1, x: 0, y: 0.5)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(width: max(size.height - 12, 10))
                .rotationEffect(.degrees(-90))
        }
        .task(id: item.edition?.uri) { await resolvePages() }
    }

    /// Fetches P1104 once and persists it; the parent recomputes the spine thickness
    /// reactively when `numberOfPages` changes.
    private func resolvePages() async {
        guard let edition = item.edition, edition.numberOfPages == nil else { return }
        if let pages = await EditionPagesLoader.shared.numberOfPages(forEditionUri: edition.uri) {
            edition.numberOfPages = pages
            try? modelContext.save()
        }
    }
}
