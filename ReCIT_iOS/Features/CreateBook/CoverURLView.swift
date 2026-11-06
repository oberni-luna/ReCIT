//
//  CoverURLView.swift
//  ReCIT_iOS
//
//  « Image depuis une URL » — a cover found on the web. Frames `V9`, `V10` and `V11` of
//  « Nouveau livre v2 » in the Figma file.
//
//  The usual way it goes: a Google Images search for the work's title and the ISBN opens in
//  Safari, the reader copies an image's address, comes back, and pastes it. The paste is a
//  `PasteButton`, so the system asks nothing: the reader's own tap is the permission. The
//  preview is loaded as soon as the address is one, and « Utiliser cette image » waits for an
//  image to be shown.
//
//  For a new book, the address is what goes to inventaire.io, as the edition seed's `image`:
//  `resolve` fetches it itself, so nothing is uploaded from here, and the bytes loaded for the
//  preview only fill the cover frame of the form. « Modifier l'édition » uploads those bytes
//  instead: `update-claim` takes a hash, not an address. Which is why the screen hands back
//  both and lets the form choose.
//
//  A group's photo comes through the same screen, without the search and without the word about
//  bibliographic data: those belong to a book's cover, and come with `init(searchedTitle:isbn:onUse:)`.
//
//  See PRD 0026.
//

import SwiftUI

struct CoverURLView: View {
    /// Long enough that typing an address does not fetch every prefix of it.
    private static let debounce: Duration = .milliseconds(400)

    @Environment(\.dismiss) private var dismiss

    /// Handed the image chosen — its reduced JPEG, and the address it came from.
    let onUse: (Data, URL) -> Void
    /// The book whose cover is looked for, when the image is one.
    private let bookCover: BookCover?

    @State private var address: String = ""
    @State private var preview: CoverURLPreview = .empty

    /// Any picture found on the web: the address, and its preview.
    init(onUse: @escaping (Data, URL) -> Void) {
        self.onUse = onUse
        self.bookCover = nil
    }

    /// A book's cover: the screen opens on a Google Images search for its title and ISBN, under
    /// the word about bibliographic data, with the « ? » that explains them.
    ///
    /// - Parameters:
    ///   - searchedTitle: What the image search asks for, with the ISBN.
    ///   - isbn: Without separators.
    init(
        searchedTitle: String,
        isbn: String,
        onUse: @escaping (Data, URL) -> Void
    ) {
        self.onUse = onUse
        self.bookCover = .init(title: searchedTitle, isbn: isbn)
    }

    var body: some View {
        DesignSystem.Form {
            if let bookCover {
                BibliographicDataNotice()

                CoverURLSearchSection(title: bookCover.title, isbn: bookCover.isbn)
            }

            Section {
                TextField("create_book.cover_url.placeholder", text: $address)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundDefault)
                    .withLabel(label: "create_book.cover_url.field")
                    .accessibilityIdentifier("e2e.createBook.coverUrl.address")

                PasteButton(payloadType: String.self) { strings in
                    Task { @MainActor in
                        if let pasted = strings.first { address = pasted }
                    }
                }
                .labelStyle(.titleAndIcon)
                .buttonBorderShape(.capsule)
                .tint(.foregroundTinted)

                CoverURLPreviewView(preview: preview)
                    .frame(maxWidth: .infinity)
            } header: {
                CreateBookSectionHeader("create_book.cover_url.address")
            } footer: {
                if let footer {
                    CreateBookSectionFooter(footer)
                }
            }
        }
        .formActionBar {
            Button {
                use()
            } label: {
                Text("create_book.cover_url.use")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.primary())
            .disabled(isUsable == false)
            .accessibilityIdentifier("e2e.createBook.coverUrl.use")
        }
        .navigationTitle(String(localized: "create_book.cover_url.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if bookCover != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    BibliographicDataHelpButton()
                }
            }
        }
        .task(id: address) {
            await loadPreview()
        }
    }

    /// A book's cover is asked to be the edition's; a group's photo has nothing to check.
    private var footer: LocalizedStringKey? {
        switch preview {
        case .empty, .loading: "create_book.cover_url.help"
        case .loaded: bookCover == nil ? nil : "create_book.cover_url.check"
        case .failed: "create_book.cover_url.not_an_image"
        }
    }

    private var isUsable: Bool {
        if case .loaded = preview { true } else { false }
    }

    /// Loads what the address points at, a beat after the last change. Cancellation is the
    /// debounce: a new address cancels this task, and the sleep is what gives it time to.
    private func loadPreview() async {
        guard let url = CoverAddress.url(from: address) else {
            preview = .empty
            return
        }

        try? await Task.sleep(for: CoverURLView.debounce)
        guard Task.isCancelled == false else { return }

        preview = .loading
        let loaded: CoverURLPreview = await CoverURLPreview.load(url)
        guard Task.isCancelled == false else { return }

        preview = loaded
    }

    /// The image becomes the edition's cover: the form that pushed this screen decides what of
    /// it goes to inventaire.io.
    private func use() {
        guard case .loaded(let jpeg, _, _) = preview,
              let url = CoverAddress.url(from: address) else { return }

        onUse(jpeg, url)
        dismiss()
    }
}

private extension CoverURLView {
    struct BookCover {
        let title: String
        let isbn: String
    }
}

/// The image the address points at, 120 × 180, and a line under it. `Form / Image Preview`
/// (`716:615`) in the Figma file.
private struct CoverURLPreviewView: View {
    let preview: CoverURLPreview

    var body: some View {
        VStack(spacing: .small) {
            frame
                .frame(width: 120, height: 180)
                .clipShape(.rect(cornerRadius: DesignSystem.CornerRadius.medium))

            caption
                .textStyle(.caption200)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, .xxSmall)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var frame: some View {
        switch preview {
        case .empty:
            Image(systemName: "photo")
                .foregroundStyle(.foregroundSecondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.backgroundSecondary)
                .overlay {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                        .strokeBorder(
                            DesignSystem.Color.borderDefault.color,
                            style: .init(lineWidth: 1, dash: [4, 4])
                        )
                }
                .accessibilityHidden(true)
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.backgroundSecondary)
        case .loaded(let jpeg, _, _):
            if let image = UIImage(data: jpeg) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
        case .failed:
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(.foregroundError)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.backgroundError)
                .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private var caption: some View {
        switch preview {
        case .empty, .loading:
            Text("create_book.cover_url.preview_placeholder")
                .foregroundStyle(.foregroundSecondary)
        case .loaded(_, let width, let height):
            Text("create_book.cover_url.dimensions \(width) \(height)")
                .foregroundStyle(.foregroundSecondary)
        case .failed:
            Text("create_book.cover_url.failed")
                .foregroundStyle(.foregroundError)
        }
    }
}
