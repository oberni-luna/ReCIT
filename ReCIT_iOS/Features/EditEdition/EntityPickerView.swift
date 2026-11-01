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
//  the publisher first. A Wikidata work or person names Wikidata entities only: inventaire.io
//  refuses the link to one of its own, so its picker shows Wikidata's results and creates none.
//

import SwiftUI

struct EntityPickerView: View {
    @Environment(SearchModel.self) private var searchModel
    @Environment(\.dismiss) private var dismiss

    let property: EditionProperty
    /// Whether the edition names a publisher a new collection can be created under.
    var hasPublisher: Bool = true
    /// Whether only Wikidata entities may be chosen — for a work or a person of Wikidata's.
    var wikidataOnly: Bool = false
    /// Handed the entity picked or created. The screen pops itself afterwards.
    let onChoose: (EditionEntityValue) -> Void

    @State private var query: String = ""
    @State private var results: [SearchResult] = []
    @State private var hasSearched: Bool = false

    private static let debounce: Duration = .milliseconds(300)

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var allowsCreation: Bool {
        property.allowsCreation && wikidataOnly == false
    }

    private var canCreate: Bool {
        allowsCreation && (property != .collection || hasPublisher)
    }

    private var candidates: [SearchResult] {
        Self.candidates(results, wikidataOnly: wikidataOnly)
    }

    /// The results that can be chosen: every one, or Wikidata's alone.
    static func candidates(_ results: [SearchResult], wikidataOnly: Bool) -> [SearchResult] {
        wikidataOnly ? results.filter { EntityEdit.linksWikidataOnly(uri: $0.uri) } : results
    }

    var body: some View {
        DesignSystem.FormList {
            if candidates.isEmpty == false {
                Section {
                    ForEach(candidates) { result in
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
                    if wikidataOnly {
                        Text("entity_picker.wikidata_only")
                    } else if property.allowsCreation {
                        Text("entity_picker.why_existing")
                    }
                }
            } else if wikidataOnly, hasSearched {
                Section {
                } footer: {
                    Text("entity_picker.wikidata_only.none")
                }
            }

            if trimmedQuery.isEmpty == false, allowsCreation {
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
        let types: [SearchResultType] = property.searchTypes
        guard types.isEmpty == false, trimmedQuery.count >= 2 else {
            results = []
            hasSearched = false
            return
        }

        try? await Task.sleep(for: EntityPickerView.debounce)
        guard Task.isCancelled == false else { return }

        results = (try? await searchModel.searchEntity(query: trimmedQuery, entityTypes: types)) ?? []
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
