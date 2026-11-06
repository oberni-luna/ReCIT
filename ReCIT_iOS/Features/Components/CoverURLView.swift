//
//  CoverURLView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 25/10/2026.
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
//  A group's photo comes through the same screen, bare. A book's cover comes through
//  `BookCoverURLView`, which heads it with the search and the word about bibliographic data.
//
//  See PRD 0026.
//

import SwiftUI

struct CoverURLView<Head: View>: View {
    /// Long enough that typing an address does not fetch every prefix of it.
    private static var debounce: Duration {
        .milliseconds(400)
    }

    @Environment(\.dismiss) private var dismiss: DismissAction

    /// Handed the image chosen — its reduced JPEG, and the address it came from.
    let onUse: (Data, URL) -> Void
    /// The sections above the address, about what the image is looked for.
    private let head: Head
    /// What the footer says under an image once it shows; nothing by default.
    private var loadedFooter: LocalizedStringKey?

    @State private var address: String = ""
    @State private var preview: CoverURLPreview = .empty

    /// A picture found on the web: the address, and its preview.
    ///
    /// - Parameter head: The sections above the address, about what the image is looked for.
    init(
        onUse: @escaping (Data, URL) -> Void,
        @ViewBuilder head: () -> Head
    ) {
        self.onUse = onUse
        self.head = head()
    }

    var body: some View {
        DesignSystem.Form {
            head

            Section {
                TextField("create_book.cover_url.placeholder", text: $address)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundDefault)
                    .withLabel(label: "create_book.cover_url.field")
                    .accessibilityIdentifier(AccessibilityID.address)

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
            .accessibilityIdentifier(AccessibilityID.use)
        }
        .navigationTitle(String(localized: "create_book.cover_url.title"))
        .navigationBarTitleDisplayMode(.inline)
        .task(id: address) {
            await loadPreview()
        }
    }

    private var footer: LocalizedStringKey? {
        switch preview {
        case .empty, .loading: "create_book.cover_url.help"
        case .loaded: loadedFooter
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

        try? await Task.sleep(for: Self.debounce)
        guard Task.isCancelled == false else { return }

        preview = .loading
        let loaded: CoverURLPreview = await CoverURLPreview.load(url)
        guard Task.isCancelled == false else { return }

        preview = loaded
    }

    /// The image goes to the form that pushed this screen, which decides what of it is sent to
    /// inventaire.io.
    private func use() {
        guard
            case .loaded(let jpeg, _, _) = preview,
            let url = CoverAddress.url(from: address)
        else {
            return
        }

        onUse(jpeg, url)
        dismiss()
    }
}

extension CoverURLView where Head == EmptyView {
    /// Any picture found on the web, with nothing above the address.
    init(onUse: @escaping (Data, URL) -> Void) {
        self.init(onUse: onUse) {
            EmptyView()
        }
    }
}

extension CoverURLView {
    /// What the footer says under an image once it shows — a book's cover asks to check it is the
    /// edition's.
    func footer(onceLoaded footer: LocalizedStringKey) -> Self {
        var copy: Self = self
        copy.loadedFooter = footer
        return copy
    }
}

private extension CoverURLView {
    enum AccessibilityID {
        static var address: String {
            "e2e.createBook.coverUrl.address"
        }

        static var use: String {
            "e2e.createBook.coverUrl.use"
        }
    }
}

#Preview {
    NavigationStack {
        CoverURLView { _, _ in }
    }
}
