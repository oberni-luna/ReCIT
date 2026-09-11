//
//  NewListFormView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 30/11/2025.
//
//  Sheet to create or edit a list. **A third mode creates then files**: handed the uri of a
//  work, the same form creates the list and puts that work in it, which is what the "…" menu's
//  « Ajouter à une nouvelle liste » opens (PRD 0014). The mode is a single optional value
//  rather than a pair of flags, so it cannot be half-set, and `submit()` reads it first. The
//  plain-creation mode called from the lists screen is untouched.
//
//  In that third mode the type picker is gone and the type is a works list: the book imposes
//  the answer, and a choice betrayed afterwards is worse than an absent one. The sequencing of
//  the two server calls is `ListModel`'s, not this form's — see `createListAndAddWork`.
//

import SwiftUI
import LBSnackBar
import SwiftData

struct ListFormView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    @Environment(\.snackBar) private var snackBar
    @Environment(ListModel.self) var listModel

    @Bindable var list: EntityList

    /// The work to file into the list once it exists, and the only thing that tells the
    /// create-then-file mode from plain creation. `nil` in the two modes that existed before.
    private let workUriToFile: String?

    init(list: EntityList = .init(_id: "", _rev: "", name: "", explanation: "", created: Date(), visibility: [], type: .work)) {
        _list = Bindable(wrappedValue: list)
        workUriToFile = nil
    }

    /// The create-then-file form, opened from a book or a work. The list is made to hold that
    /// work, so its type is set here rather than asked for.
    init(fileWorkIntoNewList workUri: String) {
        _list = Bindable(wrappedValue: .init(_id: "", _rev: "", name: "", explanation: "", created: Date(), visibility: [], type: .work))
        workUriToFile = workUri
    }

    /// Whether this form is making a list or editing one. A list only has a server id once the
    /// server has answered, so an empty id is what "does not exist yet" means here.
    ///
    /// Read by everything that differs between the two modes — the title, the type picker and
    /// the delete control — because those three disagreeing is exactly how the form came to
    /// offer deleting a list that had never existed.
    private var isCreating: Bool {
        list._id.isEmpty
    }

    private var isFilingIntoNewList: Bool {
        workUriToFile != nil
    }

    private var trimmedName: String {
        list.name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var submitTitleKey: LocalizedStringKey {
        isFilingIntoNewList ? "list.form.create_and_add" : "action.submit"
    }

    var body: some View {
        NavigationStack {
            Form {
                // Not asked when the book has already answered: a list opened from a book
                // holds that book's work, and the value is forced in the initializer.
                if isCreating, isFilingIntoNewList == false {
                    Section {
                        Picker("list.form.type", selection: $list.type) {
                            ForEach(EntityListType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .foregroundStyle(.foregroundDefault)
                    }
                }

                Section {
                    TextField("list.form.name", text: $list.name)
                        // Before `withLabel`, which wraps the field with a `Text` of its own:
                        // applied after it, the identifier lands on the pair and resolves to
                        // the label rather than to the box the scenario has to type into.
                        .accessibilityIdentifier("e2e.listForm.name")
                        .textStyle(.content300)
                        .foregroundStyle(.foregroundDefault)
                        .withLabel(label: "list.form.name")

                    TextEditor(text: $list.explanation)
                        .frame(minHeight: 48)
                        .textStyle(.content300)
                        .foregroundStyle(.foregroundDefault)
                        .withLabel(label: "list.form.description")
                }
                .listRowSeparator(.visible)
                .listSectionSeparator(.hidden)

                Section {} footer: {
                    VStack {
                        AsyncButton(action: {
                            await submit()
                        },
                                    actionOptions: [.showProgressView],
                                    label: {
                            Text(submitTitleKey)
                                .frame(maxWidth: .infinity)
                        })
                        .buttonStyle(.primary())
                        // Only the new mode refuses an empty name: the other two are left
                        // exactly as they were.
                        .disabled(isFilingIntoNewList && trimmedName.isEmpty)
                        .accessibilityIdentifier("e2e.listForm.submit")

                        // Only an existing list can be deleted. The same test decides the
                        // title and the type picker above: a list with no server id has
                        // never existed, so offering to delete it asked the endpoint to
                        // remove an empty id.
                        if !isCreating {
                            AsyncButton(action: {
                                do {
                                    try await listModel.deleteList(
                                        modelContext: modelContext,
                                        list: list
                                    )
                                    dismiss()
                                } catch {
                                    snackBar.show { SnackBarView.error(error) }
                                }
                            },
                                        actionOptions: [.showProgressView],
                                        label: {
                                Text("list.form.delete")
                                    .frame(maxWidth: .infinity)
                            })
                            .buttonStyle(.destructive())
                            .accessibilityIdentifier("e2e.listForm.delete")
                        }
                    }
                }
                .listRowSeparator(.visible)
                .listSectionSeparator(.hidden)
            }
            .applyListBackground()
            .navigationTitle(isCreating ? String(localized: "list.form.create_title") : String(localized: "list.form.edit_title"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action.close", systemImage: "xmark") {
                        dismiss()
                    }
                }
            }
        }
    }

    /// Creating-then-filing is read first, and returns: there is no path from it into the plain
    /// create-or-update write.
    ///
    /// A failing creation leaves the sheet open with what was typed — the list does not exist
    /// and the user can try again without retyping. A failing *filing* never reaches here: it
    /// is optimistic, reverts itself and reports through the shared channel, and the list the
    /// user has just watched being born stays.
    private func submit() async {
        if let workUriToFile {
            do {
                let created: EntityList = try await listModel.createListAndAddWork(
                    modelContext: modelContext,
                    name: trimmedName,
                    description: list.explanation,
                    visibility: list.visibility.map(\.rawValue),
                    workUri: workUriToFile
                )
                // Nothing on the book screen shows its lists, so the SnackBar is the only
                // thing saying where the book has landed.
                snackBar.show {
                    SnackBarView(
                        title: String(localized: "list.added_to_named \(created.name)"),
                        onDismiss: nil
                    )
                }
                dismiss()
            } catch {
                snackBar.show { SnackBarView.error(error) }
            }
            return
        }

        do {
            try await listModel.createOrUpdateList(
                modelContext: modelContext,
                list: list
            )
            dismiss()
        } catch {
            snackBar.show { SnackBarView.error(error) }
        }
    }
}

#Preview {
    ListFormView()
}
