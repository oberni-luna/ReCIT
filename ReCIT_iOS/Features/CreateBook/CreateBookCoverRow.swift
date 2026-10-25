//
//  CreateBookCoverRow.swift
//  ReCIT_iOS
//
//  The first row of the edition: its cover, and the ISBN the camera read. `Form / Cover ISBN`
//  (`701:511`) in the Figma file, shared by « Nouvelle édition », « Nouvelle œuvre » and
//  « Modifier l'édition ». It knows a picture and an ISBN, not what they belong to: each form
//  binds the picture to its own draft.
//
//  The cover is a menu of where a picture can come from (`V8`): the camera, where there is one,
//  Photos, Files, an address on the web. Once one is set the same menu offers to take it away first, then to replace it
//  from the same sources (`V12`). A work nobody has created has no cover, and `enrich` finds
//  none for an ISBN nobody knows: the frame of a new work is usually empty (`V7`), and saying
//  « Ajouter une couverture » in it is the invitation.
//
//  The ISBN is shown and not editable: it is the one fact the app is certain of, read off the
//  barcode a moment ago, and the whole form exists because the *rest* is unknown.
//
//  See PRD 0015 and PRD 0026.
//

import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

struct CreateBookCoverRow: View {
    let isbn: String
    /// What the ISBN is called above it: read off the barcode in a new book, simply « ISBN » in
    /// an edition being changed.
    var isbnLabel: String = "create_book.isbn"
    /// The picture, as JPEG bytes; `nil` is none.
    @Binding var imageData: Data?

    /// Pushes « Image depuis une URL », which the row cannot do itself: the screen it pushes
    /// belongs to the sheet's navigation stack.
    let onPickURL: () -> Void

    @State private var isCapturingCover: Bool = false
    @State private var isPickingPhoto: Bool = false
    @State private var pickedPhoto: PhotosPickerItem?
    @State private var isImportingFile: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: .medium) {
            Menu {
                if imageData != nil {
                    Button("create_book.cover.remove", systemImage: "trash", role: .destructive) {
                        setCover(nil)
                    }

                    Section("create_book.cover.replace") {
                        sources
                    }
                } else {
                    sources
                }
            } label: {
                CreateBookCoverSlot(imageData: imageData)
            }
            // The frame is the control, not the row: a plain button keeps a tap on the ISBN
            // beside it from opening the menu.
            .menuStyle(.button)
            .buttonStyle(.plain)
            .accessibilityLabel(Text(imageData == nil ? "create_book.cover.add" : "create_book.cover.change"))
            .accessibilityIdentifier("e2e.createBook.cover")

            Text(isbn)
                .textStyle(.content300)
                .foregroundStyle(.foregroundDefault)
                .accessibilityIdentifier("e2e.createBook.isbn")
                .withLabel(label: isbnLabel)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .fullScreenCover(isPresented: $isCapturingCover) {
            CoverCaptureView { data in
                setCover(data)
            }
            .ignoresSafeArea()
        }
        .photosPicker(isPresented: $isPickingPhoto, selection: $pickedPhoto, matching: .images)
        .onChange(of: pickedPhoto) { _, item in
            guard let item else { return }
            pickedPhoto = nil

            Task {
                guard let data = try? await item.loadTransferable(type: Data.self),
                      let jpeg = CoverImageReducer.jpegData(from: data) else { return }
                setCover(jpeg)
            }
        }
        .fileImporter(isPresented: $isImportingFile, allowedContentTypes: [.image]) { result in
            guard case .success(let url) = result else { return }
            // A file from Files lives outside the sandbox: it is read under the access the
            // picker granted, and only for as long as it takes.
            let isAccessing: Bool = url.startAccessingSecurityScopedResource()
            defer { if isAccessing { url.stopAccessingSecurityScopedResource() } }

            guard let data = try? Data(contentsOf: url),
                  let jpeg = CoverImageReducer.jpegData(from: data) else { return }
            setCover(jpeg)
        }
    }

    /// Where a picture can come from, in the order of the menu.
    @ViewBuilder
    private var sources: some View {
        if CoverCaptureView.isCameraAvailable {
            Button("create_book.cover.camera", systemImage: "camera") {
                isCapturingCover = true
            }
        }

        Button("create_book.cover.photos", systemImage: "photo.on.rectangle") {
            isPickingPhoto = true
        }

        Button("create_book.cover.file", systemImage: "folder") {
            isImportingFile = true
        }

        Button("create_book.cover.url", systemImage: "link", action: onPickURL)
    }

    /// A new picture, or none. What that undoes — an upload already made for the old one — is
    /// the draft's business, behind the binding.
    private func setCover(_ data: Data?) {
        imageData = data
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
