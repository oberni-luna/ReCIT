//
//  GroupSettingsView.swift
//  ReCIT_iOS
//
//  What an admin can change about a group — frame `A12`, as a sheet like « Modifier l'étagère ».
//
//  `PUT /api/groups/update-settings` takes one attribute at a time, and the form follows it: a
//  toggle is written the moment it moves, optimistically, and the two texts go together on
//  « Enregistrer », one call each for whichever changed. The photo goes with them, server first:
//  uploaded, then named, and shown once the server has agreed. The place is not offered yet
//  (PRD 0016).
//

import SwiftUI
import SwiftData

struct GroupSettingsView: View {
    @Environment(GroupModel.self) private var groupModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var storedGroups: [StoredGroup]

    let group: ReaderGroup

    @State private var name: String
    @State private var groupDescription: String
    @State private var picture: GroupPictureEdit = .unchanged
    @State private var isPickingPictureURL: Bool = false

    init(group: ReaderGroup) {
        self.group = group
        _name = State(initialValue: group.name)
        _groupDescription = State(initialValue: group.description)
    }

    /// Live from the model, so a toggle reflects what was written — or put back.
    private var current: ReaderGroup {
        groupModel.group(id: group.id, among: storedGroups) ?? group
    }

    private var hasChanges: Bool {
        name != current.name
            || groupDescription != current.description
            || picture.isChange(from: current.pictureURL)
    }

    var body: some View {
        NavigationStack {
            DesignSystem.Form {
                Section {
                    GroupPhotoPicker(
                        $picture,
                        savedPictureURL: current.pictureURL,
                        onPickURL: { isPickingPictureURL = true }
                    )
                }
                .listRowBackground(Color.clear)

                Section {
                    TextField("groups.form.name", text: $name)
                        .textStyle(.content300)
                        .foregroundStyle(.foregroundDefault)

                    TextField("groups.form.description", text: $groupDescription, axis: .vertical)
                        .lineLimit(2...5)
                        .textStyle(.content300)
                        .foregroundStyle(.foregroundDefault)
                } footer: {
                    if name.count > GroupNameRule.maximumLength {
                        Text("groups.form.name.too_long \(GroupNameRule.maximumLength)")
                            .textStyle(.footnote200)
                            .foregroundStyle(.foregroundError)
                    } else if let slug = current.slug {
                        GroupNote("groups.form.address \(slug)")
                    }
                }

                GroupAccessSection(
                    searchable: .init(
                        get: { current.searchable },
                        set: { groupModel.update(.searchable($0), on: group.id, modelContext: modelContext) }
                    ),
                    open: .init(
                        get: { current.open },
                        set: { groupModel.update(.open($0), on: group.id, modelContext: modelContext) }
                    )
                )
            }
            .navigationTitle("groups.settings")
            .navigationDestination(isPresented: $isPickingPictureURL) {
                CoverURLView { jpeg, _ in
                    picture = .replaced(jpeg)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action.close", systemImage: "xmark") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("action.save") {
                        save()
                        dismiss()
                    }
                    .disabled(hasChanges == false || GroupNameRule.accepts(name) == false)
                    .accessibilityIdentifier("e2e.groupSettings.save")
                }
            }
        }
    }

    private func save() {
        let trimmedName: String = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName != current.name {
            groupModel.update(.name(trimmedName), on: group.id, modelContext: modelContext)
        }
        let trimmedDescription: String = groupDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedDescription != current.description {
            groupModel.update(.description(trimmedDescription), on: group.id, modelContext: modelContext)
        }
        if picture.isChange(from: current.pictureURL) {
            groupModel.updatePicture(picture.imageData, on: group.id, modelContext: modelContext)
        }
    }
}
