//
//  PaintedBookView.swift
//  ReCIT_iOS
//
//  A single watercolour-painted book: a rectangle filled with the cover's dominant
//  colour, run through the `watercolorSpine` Metal shader, with a caller-supplied
//  title overlay. Resolves and persists the colour lazily on first appearance.
//  See ADR 0003.
//

import SwiftUI
import SwiftData

struct PaintedBookView<Overlay: View>: View {
    let edition: Edition?
    let size: CGSize
    let seed: Double
    @ViewBuilder var overlay: (Color) -> Overlay

    @Environment(\.modelContext) private var modelContext
    @State private var hex: String?

    var body: some View {
        let base: Color = ShelfPalette.spineColor(hex)
        let ink: Color = ShelfPalette.ink(onHex: hex)

        Rectangle()
            .fill(base)
            .colorEffect(
                ShaderLibrary.watercolorSpine(
                    .float2(Float(size.width), Float(size.height)),
                    .float(Float(seed))
                )
            )
            .overlay { overlay(ink) }
            .frame(width: size.width, height: size.height)
            .clipShape(.rect(cornerRadius: 1))
            .shadow(color: .black.opacity(0.16), radius: 1.5, x: 0, y: 1.5)
            .task(id: edition?.uri) { await resolveColor() }
            .animation(.easeIn(duration: 0.35), value: hex)
    }

    /// Uses the persisted hex when present; otherwise extracts it from the cover,
    /// persists it on the edition, and fades the spine in. Runs at most once per
    /// edition thanks to the stored value.
    private func resolveColor() async {
        if let existing = edition?.dominantColorHex, existing.isEmpty == false {
            hex = existing
            return
        }
        guard let edition,
              let urlString = edition.image,
              let url = URL(string: urlString) else { return }

        if let computed = await DominantColorExtractor.shared.hex(forImageAt: url) {
            edition.dominantColorHex = computed
            hex = computed
            try? modelContext.save()
        }
    }
}
