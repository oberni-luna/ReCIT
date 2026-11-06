//
//  ImageSourceMenu.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 06/11/2026.
//

import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

/// A picture's slot as a menu of where a picture can come from (`V8`): the camera, where there is
/// one, Photos, Files, an address on the web. Once one is set the same menu offers to take it
/// away first, then to replace it from the same sources (`V12`).
///
/// It knows the bytes picked, not what they belong to: an edition's cover, a group's photo. Every
/// picture leaves it reduced by `CoverImageReducer`.
struct ImageSourceMenu<Label: View>: View {
    private let removeTitle: LocalizedStringKey
    private let hasImage: Bool
    private let onPick: (Data) -> Void
    private let onRemove: () -> Void
    /// Pushes « Image depuis une URL », which the menu cannot do itself: the screen it pushes
    /// belongs to the sheet's navigation stack.
    private let onPickURL: () -> Void
    private let label: Label

    @State private var isCapturing: Bool = false
    @State private var isPickingPhoto: Bool = false
    @State private var pickedPhoto: PhotosPickerItem?
    @State private var isImportingFile: Bool = false

    /// - Parameters:
    ///   - removeTitle: What taking the picture away is called: « Retirer la couverture ».
    ///   - hasImage: Whether there is a picture to take away or replace.
    init(
        _ removeTitle: LocalizedStringKey,
        hasImage: Bool,
        onPick: @escaping (Data) -> Void,
        onRemove: @escaping () -> Void,
        onPickURL: @escaping () -> Void,
        @ViewBuilder label: () -> Label
    ) {
        self.removeTitle = removeTitle
        self.hasImage = hasImage
        self.onPick = onPick
        self.onRemove = onRemove
        self.onPickURL = onPickURL
        self.label = label()
    }

    var body: some View {
        Menu {
            if hasImage {
                Button(removeTitle, systemImage: "trash", role: .destructive, action: onRemove)

                Section("image_source.replace") {
                    sources
                }
            } else {
                sources
            }
        } label: {
            label
        }
        // The slot is the control, not the row: a plain button keeps a tap beside it from
        // opening the menu.
        .menuStyle(.button)
        .buttonStyle(.plain)
        .fullScreenCover(isPresented: $isCapturing) {
            CoverCaptureView(onCapture: onPick)
                .ignoresSafeArea()
        }
        .photosPicker(isPresented: $isPickingPhoto, selection: $pickedPhoto, matching: .images)
        .onChange(of: pickedPhoto) { _, item in
            guard let item else { return }
            pickedPhoto = nil

            Task {
                guard
                    let data = try? await item.loadTransferable(type: Data.self),
                    let jpeg = CoverImageReducer.jpegData(from: data)
                else {
                    return
                }
                onPick(jpeg)
            }
        }
        .fileImporter(isPresented: $isImportingFile, allowedContentTypes: [.image]) { result in
            guard case let .success(url) = result else { return }
            // A file from Files lives outside the sandbox: it is read under the access the
            // picker granted, and only for as long as it takes.
            let isAccessing: Bool = url.startAccessingSecurityScopedResource()
            defer { if isAccessing { url.stopAccessingSecurityScopedResource() } }

            guard
                let data = try? Data(contentsOf: url),
                let jpeg = CoverImageReducer.jpegData(from: data)
            else {
                return
            }
            onPick(jpeg)
        }
    }

    /// Where a picture can come from, in the order of the menu.
    @ViewBuilder
    private var sources: some View {
        if CoverCaptureView.isCameraAvailable {
            Button("image_source.camera", systemImage: "camera") {
                isCapturing = true
            }
        }

        Button("image_source.photos", systemImage: "photo.on.rectangle") {
            isPickingPhoto = true
        }

        Button("image_source.file", systemImage: "folder") {
            isImportingFile = true
        }

        Button("image_source.url", systemImage: "link", action: onPickURL)
    }
}

#Preview("Empty") {
    ImageSourceMenu(
        "create_book.cover.remove",
        hasImage: false,
        onPick: { _ in },
        onRemove: {},
        onPickURL: {},
        label: { Image(systemName: "photo") }
    )
}

#Preview("With a picture") {
    ImageSourceMenu(
        "create_book.cover.remove",
        hasImage: true,
        onPick: { _ in },
        onRemove: {},
        onPickURL: {},
        label: { Image(systemName: "photo.fill") }
    )
}
