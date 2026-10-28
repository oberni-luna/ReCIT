//
//  EntityEdit.swift
//  ReCIT_iOS
//
//  A work or a person as « Modifier l'œuvre » and « Modifier l'auteur·ice » change it: its
//  labels — a title or a name per language — and every property of its catalogue, against what
//  inventaire.io holds. A value type with no opinion about the network, like `EditionEdit`: the
//  form fills it, `EntityCreationModel.saveEntity` runs the steps it lists and tells it which
//  ones landed.
//
//  Each screen saves its own entity (Figma `814:5090`, decided on 2026-10-28): the people a
//  claim names that inventaire.io does not have are created first, then the claims go one at a
//  time, then the labels. What landed moves into `original` and `originalLabels`, so a retry
//  sends only what is left.
//
//  A Wikidata entity is shown and never sent: it is changed on Wikidata, through an account
//  this app does not hold.
//

import Foundation

struct EntityEdit: Equatable, Sendable {

    /// One label: the title or the name in one language.
    struct Label: Identifiable, Equatable, Sendable {
        let language: String
        var value: String

        var id: String { language }

        var trimmedValue: String {
            value.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    let uri: String

    /// The labels as inventaire.io holds them, after every one that landed.
    private(set) var originalLabels: [String: String]

    /// The labels as the form has them: the one shown first, then the others.
    var labels: [Label]

    /// The properties as inventaire.io holds them, after every claim that landed.
    private(set) var original: EditionProperties

    var properties: EditionProperties

    /// The language a person created from the form is labelled in: the entity's own.
    let labelLanguage: String

    init(
        uri: String,
        labels: [String: String],
        properties: EditionProperties,
        originalLanguage: String? = nil
    ) {
        self.uri = uri
        originalLabels = labels
        original = properties
        self.properties = properties

        let shown: String? = EntityLabel.language(of: labels, originalLang: originalLanguage)
        let ordered: [String] = labels.keys.sorted { lhs, rhs in
            if lhs == shown { return true }
            if rhs == shown { return false }
            return lhs < rhs
        }
        self.labels = ordered.map { Label(language: $0, value: labels[$0] ?? "") }
        labelLanguage = shown ?? originalLanguage ?? ResolveRequestBuilder.defaultLabelLanguage
    }

    var catalogue: EditionProperty.Catalogue {
        properties.catalogue
    }

    /// One of inventaire.io's own. A Wikidata entity is changed on Wikidata.
    var isEditable: Bool {
        uri.hasPrefix("inv:")
    }

    /// The name the screen and the rows beneath it show: the first label that says something.
    var displayName: String {
        labels.lazy.map(\.trimmedValue).first { $0.isEmpty == false } ?? ""
    }

    // MARK: - Labels

    /// The languages a label can be added in, less those the entity has one in.
    var addableLanguages: [String] {
        Self.labelLanguages.filter { language in labels.contains { $0.language == language } == false }
    }

    /// Adds an empty label in `language`, for the reader to fill.
    mutating func addLabel(language: String) {
        guard labels.contains(where: { $0.language == language }) == false else { return }
        labels.append(.init(language: language, value: ""))
    }

    /// The languages offered by « Ajouter dans une autre langue »: those the app's readers
    /// most often write in. Any other is added on the website.
    static let labelLanguages: [String] = [
        "fr", "en", "de", "es", "it", "pt", "nl", "ca", "eu", "br", "oc", "sv", "da", "nb", "fi",
        "pl", "cs", "ru", "uk", "bg", "el", "tr", "ar", "he", "ja", "zh", "ko"
    ]

    // MARK: - What there is to send

    /// The labels changed or added. One emptied is not sent: `update-label` cannot take a label
    /// away, so the form refuses to save it (`isSaveable`).
    var labelUpdates: [EntityLabelUpdate] {
        labels.compactMap { label in
            let value: String = label.trimmedValue
            let before: String? = originalLabels[label.language]?.trimmingCharacters(in: .whitespacesAndNewlines)
            guard value.isEmpty == false, value != before else { return nil }
            return .init(uri: uri, lang: label.language, value: value)
        }
    }

    var claimUpdates: [EditionClaimUpdate] {
        properties.updates(since: original, on: uri)
    }

    var hasChanges: Bool {
        labelUpdates.isEmpty == false || properties.differs(from: original)
    }

    /// Whether there is something to send, and it can be sent: no label it had emptied, and a
    /// name left to show.
    var isSaveable: Bool {
        guard isEditable, hasChanges, displayName.isEmpty == false else { return false }
        return labels.allSatisfy { originalLabels[$0.language] == nil || $0.trimmedValue.isEmpty == false }
    }

    /// The next request of the save, or `nil` once everything has landed.
    var nextStep: EditionEditStep? {
        for pending in properties.pendingEntities {
            guard let kind = EntityCreationKind(for: pending.property, publisherUri: nil) else { continue }
            return .createEntity(id: pending.entity.id, label: pending.entity.trimmedLabel, language: labelLanguage, kind: kind)
        }
        if let update = claimUpdates.first {
            return .claim(update)
        }
        return labelUpdates.first.map { .label($0) }
    }

    // MARK: - What landed

    mutating func entityCreated(id: UUID, uri: String) {
        properties.entityCreated(id: id, uri: uri)
    }

    mutating func landed(_ update: EditionClaimUpdate) {
        original.apply(update, from: properties)
    }

    mutating func landed(_ update: EntityLabelUpdate) {
        originalLabels[update.lang] = update.value
    }

    /// Shows a person this entity names under a new name: one just renamed in « Modifier
    /// l'auteur·ice ».
    mutating func rename(uri: String, label: String) {
        properties.rename(uri: uri, label: label)
        original.rename(uri: uri, label: label)
    }

    // MARK: - Showing

    /// A work as « Édition de » lists it: its title, and the authors it names.
    var editionWork: EditionWork {
        .init(
            uri: uri,
            title: displayName,
            authors: properties.entities(of: .author).compactMap { author in
                author.uri.map { NewBookAuthor(name: author.trimmedLabel, uri: $0) }
            },
            titleLanguage: labels.first?.language
        )
    }
}
