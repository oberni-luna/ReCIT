//
//  PaintedBookView.swift
//  ReCIT_iOS
//
//  A book's spine, built from a sliver of its own cover: the leftmost strip stretched to
//  the spine size, with the caller's title overlaid in a colour picked for legibility and
//  a parchment placeholder until the cover loads. Used by standing spines and pile books.
//  See PRD 0002 / ADR 0003.
//

import SwiftUI

struct PaintedBookView<Overlay: View>: View {
    let edition: Edition?
    let size: CGSize
    @ViewBuilder var overlay: (Color) -> Overlay

    @State private var strip: SpineStripLoader.Strip?

    private var titleColor: Color {
        guard let strip else { return .init(hex: "#3A2E24") } // dark ink on parchment
        return strip.titleIsDark ? .init(hex: "#2A2A2A") : .white
    }

    var body: some View {
        Group {
            if let strip {
                Image(uiImage: strip.image)
                    .resizable()
                    .interpolation(.medium)
            } else {
                Rectangle().fill(ShelfPalette.parchment)
            }
        }
        .overlay { overlay(titleColor) }
        .frame(width: size.width, height: size.height)
        .clipShape(.rect(cornerRadius: 1))
        .shadow(color: .black.opacity(0.16), radius: 1.5, x: 0, y: 1.5)
        .task(id: edition?.uri) { await load() }
        .animation(.easeIn(duration: 0.3), value: strip == nil)
    }

    private func load() async {
        guard strip == nil,
              let edition,
              let urlString = edition.image,
              let url = URL(string: urlString) else { return }
        strip = await SpineStripLoader.shared.strip(forEditionUri: edition.uri, url: url)
    }
}
