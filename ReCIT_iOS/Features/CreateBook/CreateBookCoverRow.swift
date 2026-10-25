//
//  CreateBookCoverRow.swift
//  ReCIT_iOS
//
//  The first row of the edition: its cover, and the ISBN the camera read. `Form / Cover ISBN`
//  (`701:511`) in the Figma file, shared by « Nouvelle édition » and « Nouvelle œuvre ».
//
//  The ISBN is shown and not editable: it is the one fact the app is certain of, read off the
//  barcode a moment ago, and the whole form exists because the *rest* is unknown.
//
//  See PRD 0015 and PRD 0021.
//

import SwiftUI

struct CreateBookCoverRow: View {
    @Binding var draft: NewBookDraft

    /// Whether the camera is up. The cover is the one thing in this form that is taken rather
    /// than typed.
    @State private var isCapturingCover: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: .medium) {
            Button {
                isCapturingCover = true
            } label: {
                CreateBookCoverSlot(imageData: draft.coverImageData)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("e2e.createBook.cover")

            Text(draft.isbn)
                .textStyle(.content300)
                .foregroundStyle(.foregroundDefault)
                .accessibilityIdentifier("e2e.createBook.isbn")
                .withLabel(label: "create_book.isbn")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .fullScreenCover(isPresented: $isCapturingCover) {
            CoverCaptureView { data in
                draft.coverImageData = data
                // A new photograph invalidates the one already uploaded, if the reader is
                // retrying after a failure: the next publication sends this one.
                draft.coverImageUrl = nil
            }
            .ignoresSafeArea()
        }
    }
}

/// The cover slot: a photograph taken, or a dashed frame inviting one.
///
/// Facultative, and drawn so: a dashed outline rather than a filled control, because the book
/// is published with or without it. What it is for is written under it, since a camera glyph
/// alone in a form about a book could as easily mean the barcode.
private struct CreateBookCoverSlot: View {
    let imageData: Data?

    var body: some View {
        slot
            .frame(width: 88, height: 132)
            .background(.backgroundSecondary)
            .clipShape(.rect(cornerRadius: DesignSystem.CornerRadius.medium))
            .overlay {
                if imageData == nil {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                        .strokeBorder(
                            DesignSystem.Color.borderDefault.color,
                            style: .init(lineWidth: 1, dash: [4, 4])
                        )
                }
            }
            .accessibilityLabel(Text("create_book.cover.take"))
    }

    @ViewBuilder
    private var slot: some View {
        if let imageData, let image = UIImage(data: imageData) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            VStack(spacing: .small) {
                Image(systemName: "camera")
                    .foregroundStyle(.foregroundTinted)

                Text("create_book.cover.take")
                    .textStyle(.caption200)
                    .foregroundStyle(.foregroundSecondary)
                    .multilineTextAlignment(.center)
                    // 88 points is narrower than a long French word: without this, « photo-
                    // graphier » broke across two lines mid-syllable.
                    .minimumScaleFactor(0.8)
            }
            .padding(.all, .small)
        }
    }
}
