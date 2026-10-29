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
//  See PRD 0026.
//

import SwiftUI

struct CoverURLView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss

    /// What the image search asks for, with the ISBN.
    let searchedTitle: String
    /// Without separators.
    let isbn: String
    /// Handed the image chosen — its reduced JPEG, and the address it came from.
    let onUse: (Data, URL) -> Void

    @State private var address: String = ""
    @State private var preview: CoverURLPreview = .empty

    /// Long enough that typing an address does not fetch every prefix of it.
    private static let debounce: Duration = .milliseconds(400)

    var body: some View {
        DesignSystem.Form {
            BibliographicDataNotice()

            Section {
                Button {
                    if let url = CoverAddress.googleImagesURL(title: searchedTitle, isbn: isbn) {
                        openURL(url)
                    }
                } label: {
                    Label("create_book.cover_url.search", systemImage: "magnifyingglass")
                        .textStyle(.content300)
                        .foregroundStyle(.foregroundTinted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("e2e.createBook.coverUrl.search")
            } header: {
                CreateBookSectionHeader("create_book.cover_url.find")
            } footer: {
                CreateBookSectionFooter("create_book.cover_url.find_help")
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
                CreateBookSectionFooter(footer)
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
        .bibliographicDataHelpButton()
        .task(id: address) {
            await loadPreview()
        }
    }

    private var footer: LocalizedStringKey {
        switch preview {
        case .empty, .loading: "create_book.cover_url.help"
        case .loaded: "create_book.cover_url.check"
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
