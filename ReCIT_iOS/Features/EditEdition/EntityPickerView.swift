//
//  EntityPickerView.swift
//  ReCIT_iOS
//
//  Choosing an entity an edition names — a publisher, a collection, a language, a person —
//  existing ones first, creating one last. The shape of the author search (`AuthorPickerView`),
//  for every other search type, and for the same reason: the duplicate is the one piece of
//  damage a contributor of good faith does, so the existing answer is the easy one, and
//  « Créer » sits under them all.
//
//  A language is only chosen, never created: Wikidata has them all. A collection is created
//  under the edition's publisher, as inventaire.io requires; without one, the row says to choose
//  the publisher first.
//

import SwiftUI

struct EntityPickerView: View {
    @Environment(SearchModel.self) private var searchModel
    @Environment(\.dismiss) private var dismiss

    let property: EditionProperty
    /// Whether the edition names a publisher a new collection can be created under.
    var hasPublisher: Bool = true
    /// Handed the entity picked or created. The screen pops itself afterwards.
    let onChoose: (EditionEntityValue) -> Void

    @State private var query: String = ""
    @State private var results: [SearchResult] = []
    @State private var hasSearched: Bool = false

    private static let debounce: Duration = .milliseconds(300)

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canCreate: Bool {
        property.allowsCreation && (property != .collection || hasPublisher)
    }

    var body: some View {
        List {
            if results.isEmpty == false {
                Section {
                    ForEach(results) { result in
                        Button {
                            onChoose(.init(uri: result.uri, label: result.title, detail: result.description))
                            dismiss()
                        } label: {
                            EntityPickerRow(result: result)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("entity_picker.existing")
                } footer: {
                    if property.allowsCreation {
                        Text("entity_picker.why_existing")
                    }
                }
            }

            if trimmedQuery.isEmpty == false, property.allowsCreation {
                Section {
                    Button {
                        onChoose(.init(label: trimmedQuery))
                        dismiss()
                    } label: {
                        Label("entity_picker.create \(trimmedQuery)", systemImage: "plus")
                            .textStyle(.content300)
                            .foregroundStyle(canCreate ? .foregroundTinted : .foregroundDisable)
                    }
                    .buttonStyle(.plain)
                    .disabled(canCreate == false)
                    .accessibilityIdentifier("e2e.editEdition.picker.create")
                } footer: {
                    if canCreate == false {
                        Text("entity_picker.collection_needs_publisher")
                    } else if hasSearched, results.isEmpty {
                        Text("entity_picker.no_result")
                    }
                }
            }
        }
        .applyListBackground()
        .searchable(text: $query, prompt: Text("entity_picker.prompt"))
        .autocorrectionDisabled()
        .navigationTitle(String(localized: String.LocalizationValue(property.label)))
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("e2e.editEdition.picker")
        .task(id: query) {
            await search()
        }
    }

    /// Runs the search a beat after the last keystroke; a new query cancels this one.
    private func search() async {
        guard let type = property.searchType, trimmedQuery.count >= 2 else {
            results = []
            hasSearched = false
            return
        }

        try? await Task.sleep(for: EntityPickerView.debounce)
        guard Task.isCancelled == false else { return }

        results = (try? await searchModel.searchEntity(query: trimmedQuery, entityTypes: [type])) ?? []
        hasSearched = true
    }
}

/// One candidate: the name, and what tells it apart.
private struct EntityPickerRow: View {
    let result: SearchResult

    var body: some View {
        VStack(alignment: .leading, spacing: .xxSmall) {
            Text(result.title)
                .textStyle(.content400Bold)
                .foregroundStyle(.foregroundDefault)

            if let description = result.description, description.isEmpty == false {
                Text(description)
                    .textStyle(.footnote200)
                    .foregroundStyle(.foregroundSecondary)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(.rect)
    }
}
