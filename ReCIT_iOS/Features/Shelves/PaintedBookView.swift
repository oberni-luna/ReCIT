//
//  PaintedBookView.swift
//  ReCIT_iOS
//
//  A book's spine, built from a sliver of its own cover: the leftmost strip stretched to
//  the spine size, with the caller's title overlaid in a colour picked for legibility and
//  a parchment placeholder until the cover loads. Used by standing spines and pile books;
//  a lying book gets the sliver turned a quarter turn so the cover runs along its length.
//  See PRD 0002 / ADR 0003.
//

import SwiftUI

struct PaintedBookView<Overlay: View>: View {

    let edition: Edition?
    let size: CGSize
    var orientation: ShelfBookOrientation = .standing
    /// Whether to stand in a sheet of parchment until the cover has loaded. The focus overlay
    /// turns it off: the shelf's own book is still drawn underneath, so a placeholder there
    /// only ever reads as a flash.
    var showsPlaceholder: Bool = true
    @ViewBuilder var overlay: (Color) -> Overlay

    /// The strip last loaded here, and the book it belongs to. Keyed, because this view is
    /// reused for every book the finger crosses in the focus overlay — an unkeyed strip kept
    /// painting the first book's cover onto all the others.
    @State private var loadedUri: String?
    @State private var loadedStrip: SpineStripLoader.Strip?

    /// This book's strip: the one loaded here if it is still the right book, otherwise
    /// whatever the cache already holds, which is the common case on a shelf.
    private var strip: SpineStripLoader.Strip? {
        guard let uri = edition?.uri else { return nil }
        if loadedUri == uri { return loadedStrip }
        return SpineStripLoader.cachedStrip(forEditionUri: uri)
    }

    private var titleColor: Color {
        guard let strip else { return .init(hex: "#3A2E24") } // dark ink on parchment
        return strip.titleIsDark ? .init(hex: "#2A2A2A") : .white
    }

    private func paint(_ strip: SpineStripLoader.Strip) -> UIImage {
        switch orientation {
        case .standing: strip.image
        case .lying: strip.lyingImage
        }
    }

    var body: some View {
        Group {
            if let strip {
                Image(uiImage: paint(strip))
                    .resizable()
                    .interpolation(.medium)
            } else if showsPlaceholder {
                Rectangle().fill(ShelfPalette.parchment)
            } else {
                Color.clear
            }
        }
        .overlay { overlay(titleColor) }
        .frame(width: size.width, height: size.height)
        .clipShape(.rect(cornerRadius: 1))
        .shadow(color: .black.opacity(0.16), radius: 1.5, x: 0, y: 1.5)
        .task(id: edition?.uri) { await load() }
    }

    /// Paints this book's own cover. The old paint is dropped first: when the view is reused
    /// for another book — as the focus overlay does while the finger slides — keeping it
    /// would leave the previous book's cover on this one.
    private func load() async {
        guard strip == nil,
              let edition,
              let urlString = edition.image,
              let url = URL(string: urlString) else { return }
        guard let loaded = await SpineStripLoader.shared.strip(forEditionUri: edition.uri, url: url) else { return }
        SpineStripLoader.remember(loaded, forEditionUri: edition.uri)
        loadedUri = edition.uri
        loadedStrip = loaded
    }
}
