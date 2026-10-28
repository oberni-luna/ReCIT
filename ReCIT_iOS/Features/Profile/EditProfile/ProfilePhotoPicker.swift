//
//  ProfilePhotoPicker.swift
//  ReCIT_iOS
//
//  The picture at the head of « Modifier le profil », and the menu it opens: the camera where there
//  is one, Photos, the account's Gravatar, and — once there is a picture — taking it away
//  (`Form / Avatar Picker`, frames `A2` and `A3` in the Figma file).
//
//  It only changes the draft. Nothing is uploaded until « Enregistrer », so a picture chosen and
//  then replaced costs nothing, and the preview is the bytes that will leave the phone.
//

import LBSnackBar
import PhotosUI
import SwiftUI

struct ProfilePhotoPicker: View {
    @Environment(UserModel.self) private var userModel
    @Environment(\.snackBar) private var snackBar

    /// The picture on the server, shown while the draft has not touched it.
    let savedPictureURL: String?
    @Binding var draft: ProfileDraft

    @State private var isCapturing: Bool = false
    @State private var isPickingPhoto: Bool = false
    @State private var pickedPhoto: PhotosPickerItem?
    @State private var isLoadingGravatar: Bool = false

    var body: some View {
        Menu {
            if draft.showsPicture {
                Button("edit_profile.photo.remove", systemImage: "trash", role: .destructive) {
                    draft.picture = .removed
                }
            }

            Section {
                if CoverCaptureView.isCameraAvailable {
                    Button("edit_profile.photo.camera", systemImage: "camera") {
                        isCapturing = true
                    }
                }

                Button("edit_profile.photo.photos", systemImage: "photo.on.rectangle") {
                    isPickingPhoto = true
                }

                Button("edit_profile.photo.gravatar", systemImage: "person.crop.circle") {
                    Task { await loadGravatar() }
                }
            }
        } label: {
            VStack(spacing: .small) {
                ProfilePhotoPreview(
                    picture: draft.picture,
                    savedPictureURL: savedPictureURL,
                    isLoading: isLoadingGravatar
                )

                Text("edit_profile.photo.change")
                    .textStyle(.action300)
                    .foregroundStyle(.foregroundTinted)
            }
            .frame(maxWidth: .infinity)
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .accessibilityIdentifier("e2e.editProfile.photo")
        .fullScreenCover(isPresented: $isCapturing) {
            CoverCaptureView { data in
                draft.picture = .replaced(data)
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
                draft.picture = .replaced(jpeg)
            }
        }
    }

    private func loadGravatar() async {
        isLoadingGravatar = true
        defer { isLoadingGravatar = false }

        do {
            if let data = try await userModel.gravatarImage() {
                draft.picture = .replaced(data)
            } else {
                snackBar.show {
                    SnackBarView(
                        title: String(localized: "edit_profile.photo.no_gravatar"),
                        onDismiss: nil
                    )
                }
            }
        } catch {
            snackBar.show { SnackBarView.error(error) }
        }
    }
}

/// The round picture itself: the bytes the draft holds, the server's picture, or the person glyph
/// on `backgroundDisable` — with the camera badge that says it can be changed.
private struct ProfilePhotoPreview: View {
    static let diameter: CGFloat = 104

    let picture: ProfileDraft.Picture
    let savedPictureURL: String?
    let isLoading: Bool

    var body: some View {
        content
            .frame(width: Self.diameter, height: Self.diameter)
            .background(.backgroundDisable)
            .clipShape(.circle)
            .overlay {
                if isLoading {
                    ProgressView()
                }
            }
            .overlay(alignment: .bottomTrailing) {
                Image(systemName: "camera")
                    .font(.footnote)
                    .foregroundStyle(.foregroundInverse)
                    .frame(width: 34, height: 34)
                    .background(DesignSystem.Color.backgroundTintedInverse.color, in: .circle)
                    .overlay {
                        Circle()
                            .strokeBorder(DesignSystem.Color.backgroundForm.color, lineWidth: 3)
                    }
            }
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var content: some View {
        switch picture {
        case .replaced(let data):
            if let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholder
            }
        case .removed:
            placeholder
        case .unchanged:
            if let savedPictureURL, let url = URL(string: savedPictureURL) {
                CachedAsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    placeholder
                }
            } else {
                placeholder
            }
        }
    }

    private var placeholder: some View {
        Image(systemName: "person")
            .font(.largeTitle)
            .foregroundStyle(.foregroundSecondary)
    }
}
