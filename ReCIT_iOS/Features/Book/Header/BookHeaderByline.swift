//
//  BookHeaderByline.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 22/11/2026.
//

import SwiftUI

/// « Alexandre Dumas · Tome I » under the title of the Fiche livre's header: who wrote the book,
/// then its subtitle. Not a link: an author opens from their row in Présentation. Folds away with
/// the room above it.
struct BookHeaderByline: View {
    private let authorNames: [String]
    private let subtitle: String?
    /// 0 at rest, 1 once folded.
    private let progress: CGFloat
    /// The line's height and the room above it, at rest.
    private let height: CGFloat
    /// Told the line's height and the room above it, which the fold is measured from.
    private let onMeasure: (CGFloat) -> Void

    init(
        authorNames: [String],
        subtitle: String?,
        progress: CGFloat,
        height: CGFloat,
        onMeasure: @escaping (CGFloat) -> Void
    ) {
        self.authorNames = authorNames
        self.subtitle = subtitle
        self.progress = progress
        self.height = height
        self.onMeasure = onMeasure
    }

    /// The authors as a book row names them, three at most, then the subtitle; `nil` when there
    /// is neither.
    private var text: String? {
        let authors: String? = authorNames.isEmpty ? nil : AuthorNamesSummary(authorNames).text
        let parts: [String] = [authors, subtitle].compactMap { $0 }.filter { $0.isEmpty == false }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    var body: some View {
        if let text {
            Text(text)
                .textStyle(.content300)
                .foregroundStyle(.foregroundSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, .small)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
                    onMeasure(height)
                }
                .opacity(1 - progress)
                .frame(maxWidth: .infinity)
                .frame(height: height * (1 - progress), alignment: .top)
                .clipped()
                .allowsHitTesting(false)
        }
    }
}

#Preview {
    @Previewable @State var height: CGFloat = 0

    BookHeaderByline(
        authorNames: ["Alexandre Dumas"],
        subtitle: "Tome I",
        progress: 0,
        height: height
    ) { height = $0 }
}
