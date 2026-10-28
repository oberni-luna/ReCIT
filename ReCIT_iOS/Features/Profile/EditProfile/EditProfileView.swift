//
//  EditProfileView.swift
//  ReCIT_iOS
//
//  « Modifier le profil », pushed from the Profil: the picture, the name, the bio — what every
//  reader sees of the account (frames `A2` to `A4` in the Figma file, PRD 0029).
//
//  One form, one « Enregistrer », server first: `PUT /api/user` takes a single attribute per
//  request, so `ProfileDraft` lists what changed and `UserModel.saveProfile` sends it in order.
//  A refusal part of the way keeps what went through, says what did not, and the next
//  « Enregistrer » sends only the rest. The screen closes once everything has landed.
//
//  The position is placed on a screen of its own, which hands it back to the draft.
//
//  The name is checked while it is typed, the way the sign-up form checks it, and a name taken
//  or a bio too long greys « Enregistrer » out before anything is sent.
//

import SwiftUI
import SwiftData

struct EditProfileView: View {
    @Environment(UserModel.self) private var userModel
    @Environment(AuthModel.self) private var authModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let user: User

    @State private var draft: ProfileDraft
    @State private var usernameCheck: FieldAvailability = .init(field: .username)
    @State private var failure: ProfileSaveFailure?
    @State private var isPlacingPosition: Bool = false

    /// The pause before a name is asked about: the availability endpoint answers `429` to a
    /// request a keystroke.
    private static let checkDelay: Duration = .milliseconds(600)

    init(user: User) {
        self.user = user
        self._draft = .init(initialValue: .init(user: user))
    }

    private var canSave: Bool {
        draft.isSaveable && (draft.usernameNeedsCheck == false || usernameCheck.isRefused == false)
    }

    var body: some View {
        DesignSystem.Form {
            Section {
                ProfilePhotoPicker(savedPictureURL: user.avatarURLValue, draft: $draft)
            }
            .listRowBackground(Color.clear)

            if let failure {
                Section {
                    CreateBookFailureBanner(title: failure.title, explanation: failure.explanation)
                }
                .listRowInsets(.init())
                .listRowBackground(Color.clear)
            }

            Section {
                TextField("edit_profile.username", text: $draft.username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textContentType(.username)
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundDefault)
                    .accessibilityIdentifier("e2e.editProfile.username")
                    .withLabel(label: "edit_profile.username")

                ProfileBioField(draft: $draft)
            } footer: {
                VStack(alignment: .leading, spacing: .xSmall) {
                    if draft.usernameNeedsCheck, let message = usernameCheck.message {
                        Text(message)
                            .textStyle(.footnote200)
                            .foregroundStyle(.foregroundError)
                    }

                    CreateBookSectionFooter("edit_profile.public.footer")
                }
            }

            ProfilePositionSection(position: draft.position) {
                isPlacingPosition = true
            }
        }
        .navigationDestination(isPresented: $isPlacingPosition) {
            ProfilePositionView(draft: $draft)
        }
        .navigationTitle("edit_profile.title")
        .formActionBar {
            AsyncButton(
                action: save,
                actionOptions: [.showProgressView],
                label: {
                    Text(failure == nil ? "action.save" : "create_book.retry")
                        .frame(maxWidth: .infinity)
                }
            )
            .buttonStyle(.primary())
            .disabled(canSave == false)
            .accessibilityIdentifier("e2e.editProfile.save")
        }
        .task(id: draft.username) {
            await checkUsername()
        }
    }

    /// One live check, debounced, cancelled by `.task(id:)` when the name changes again. The
    /// account's own name — in any case — is never asked about: the server would call it taken.
    private func checkUsername() async {
        guard draft.usernameNeedsCheck else { return }

        let typed: String = draft.username.trimmingCharacters(in: .whitespacesAndNewlines)
        usernameCheck.edited(to: typed)
        guard let query = usernameCheck.pendingQuery else { return }

        do {
            try await Task.sleep(for: Self.checkDelay)
        } catch {
            return
        }

        let outcome: FieldAvailability.Outcome = await authModel.usernameAvailability(query)
        usernameCheck.apply(outcome, for: query)
    }

    private func save() async {
        do {
            try await userModel.saveProfile(draft.changes, modelContext: modelContext)
            dismiss()
        } catch {
            draft.markLanded(error.landed)
            failure = error
        }
    }
}
