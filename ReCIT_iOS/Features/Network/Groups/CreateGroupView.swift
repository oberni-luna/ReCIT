//
//  CreateGroupView.swift
//  ReCIT_iOS
//
//  Starting a group — frame `A11`, as a sheet like the étagère and list forms rather than the
//  pushed screen the maquette draws: every other creation form of the app is one.
//
//  The only write of the Groupes segment that waits for the server (see
//  `GroupModel.createGroup`): the button spins, a refusal is said under it, and a success closes
//  the sheet onto the new group's screen.
//

import SwiftUI

struct CreateGroupView: View {
    @Environment(GroupModel.self) private var groupModel
    @Environment(\.dismiss) private var dismiss

    /// Told the new group's id once it exists, so the presenter can open it.
    let onCreated: (String) -> Void

    @State private var name: String = ""
    @State private var groupDescription: String = ""
    // The server's own defaults: a group can be found, and lets nobody in unasked.
    @State private var searchable: Bool = true
    @State private var open: Bool = false
    @State private var failed: Bool = false

    private var canSubmit: Bool {
        GroupNameRule.accepts(name)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("groups.form.name", text: $name)
                        .textStyle(.content300)
                        .foregroundStyle(.foregroundDefault)
                        .accessibilityIdentifier("e2e.groupForm.name")

                    TextField("groups.form.description", text: $groupDescription, axis: .vertical)
                        .lineLimit(2...5)
                        .textStyle(.content300)
                        .foregroundStyle(.foregroundDefault)
                } footer: {
                    if name.count > GroupNameRule.maximumLength {
                        Text("groups.form.name.too_long \(GroupNameRule.maximumLength)")
                            .textStyle(.footnote200)
                            .foregroundStyle(.foregroundError)
                    }
                }

                GroupAccessSection(searchable: $searchable, open: $open)

                Section {} footer: {
                    VStack(spacing: .small) {
                        AsyncButton(
                            action: { await create() },
                            actionOptions: [.showProgressView, .disableButton],
                            label: {
                                Text("groups.form.create")
                                    .frame(maxWidth: .infinity)
                            }
                        )
                        .buttonStyle(.primary())
                        .disabled(canSubmit == false)
                        .accessibilityIdentifier("e2e.groupForm.create")

                        GroupNote(failed ? "groups.form.create.failed" : "groups.form.create.note")
                    }
                }
            }
            .applyListBackground()
            .navigationTitle("groups.form.new")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action.close", systemImage: "xmark") { dismiss() }
                }
            }
        }
    }

    private func create() async {
        do {
            let group: ReaderGroup = try await groupModel.createGroup(
                name: name,
                description: groupDescription,
                searchable: searchable,
                open: open
            )
            dismiss()
            onCreated(group.id)
        } catch {
            failed = true
        }
    }
}
