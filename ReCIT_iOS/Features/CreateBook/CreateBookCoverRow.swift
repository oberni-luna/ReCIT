//
//  CreateBookCoverRow.swift
//  ReCIT_iOS
//
//  The first row of the edition: its cover, and the ISBN the camera read. `Form / Cover ISBN`
//  (`701:511`) in the Figma file, shared by « Nouvelle édition », « Nouvelle œuvre » and
//  « Modifier l'édition ». It knows a picture and an ISBN, not what they belong to: each form
//  binds the picture to its own draft.
//
//  The cover is a menu of where a picture can come from (`V8`, `ImageSourceMenu`): the camera,
//  where there is one, Photos, Files, an address on the web. Once one is set the same menu offers to take it away first, then to replace it
//  from the same sources (`V12`). A work nobody has created has no cover, and `enrich` finds
//  none for an ISBN nobody knows: the frame of a new work is usually empty (`V7`), and saying
//  « Ajouter une couverture » in it is the invitation.
//
//  The ISBN is shown and not editable: it is the one fact the app is certain of, read off the
//  barcode a moment ago, and the whole form exists because the *rest* is unknown. An edition
//  being changed shows its ISBN-10 under it, and nothing at all when it has no ISBN — a label
//  over an empty line read as a field left blank.
//
//  See PRD 0015 and PRD 0026.
//

import SwiftUI

struct CreateBookCoverRow: View {
    let isbn: String
    /// What the ISBN is called above it: read off the barcode in a new book, simply « ISBN » in
    /// an edition being changed.
    var isbnLabel: String = "create_book.isbn"
    /// The ISBN-10, shown under the ISBN when there is one.
    var isbn10: String?
    /// The picture, as JPEG bytes; `nil` is none. What changing it undoes — an upload already
    /// made for the old one — is the draft's business, behind the binding.
    @Binding var imageData: Data?

    /// Pushes « Image depuis une URL », which the row cannot do itself: the screen it pushes
    /// belongs to the sheet's navigation stack.
    let onPickURL: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: .medium) {
            ImageSourceMenu(
                "create_book.cover.remove",
                hasImage: imageData != nil,
                onPick: { imageData = $0 },
                onRemove: { imageData = nil },
                onPickURL: onPickURL,
                label: { CreateBookCoverSlot(imageData: imageData) }
            )
            .accessibilityLabel(Text(imageData == nil ? "create_book.cover.add" : "create_book.cover.change"))
            .accessibilityIdentifier("e2e.createBook.cover")

            VStack(alignment: .leading, spacing: .small) {
                if isbn.isEmpty == false {
                    Text(isbn)
                        .textStyle(.content300)
                        .foregroundStyle(.foregroundDefault)
                        .accessibilityIdentifier("e2e.createBook.isbn")
                        .withLabel(label: isbnLabel)
                }

                if let isbn10, isbn10.isEmpty == false {
                    Text(isbn10)
                        .textStyle(.content300)
                        .foregroundStyle(.foregroundDefault)
                        .withLabel(label: "edit_edition.isbn10")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

/// The cover slot: the picture chosen, or a dashed frame inviting one.
///
/// Facultative, and drawn so: a dashed outline rather than a filled control, because the book
/// is published with or without it. What it is for is written under the glyph, since a picture
/// glyph alone in a form about a book could as easily mean anything.
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
    }

    @ViewBuilder
    private var slot: some View {
        if let imageData, let image = UIImage(data: imageData) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            VStack(spacing: .small) {
                Image(systemName: "photo")
                    .foregroundStyle(.foregroundTinted)

                Text("create_book.cover.add")
                    .textStyle(.caption200)
                    .foregroundStyle(.foregroundSecondary)
                    .multilineTextAlignment(.center)
                    // 88 points is narrower than a long French word: without this, « couver-
                    // ture » broke across two lines mid-syllable.
                    .minimumScaleFactor(0.8)
            }
            .padding(.all, .small)
        }
    }
}
