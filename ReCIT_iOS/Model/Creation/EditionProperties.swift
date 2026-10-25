//
//  EditionProperties.swift
//  ReCIT_iOS
//
//  The values of an edition's catalogue properties (`EditionProperty`) — its publisher,
//  collection, date, language, format, counts, contributors, identifiers and links — as the form
//  holds them. A value type with no opinion about the network, shared by the edit of an edition
//  that exists and the draft of one being created.
//
//  It answers two questions the save asks: which entities have to be created before a claim can
//  name them, and — against the values the form opened on — which claims to send. A
//  single-valued property sends one update that names the value it replaces; a multivalued one
//  sends one update per value added or taken away.
//

import Foundation

struct EditionProperties: Equatable, Sendable {

    /// The values, keyed by property uri, in the order they were read or added. A property with
    /// no value has no key.
    private(set) var values: [String: [EditionClaimValue]]

    init(values: [String: [EditionClaimValue]] = [:]) {
        self.values = values.filter { $0.value.isEmpty == false }
    }

    /// Reads the catalogue's properties out of an entity's claims. Entity values are named with
    /// `labels`, keyed by uri; one the server did not name keeps its uri as its label.
    init(
        claims: [String: [ClaimValue]],
        labels: [String: String]
    ) {
        var values: [String: [EditionClaimValue]] = [:]
        for property in EditionProperty.all {
            let literals: [ClaimLiteral] = claims[property.uri]?.compactMap(ClaimLiteral.init) ?? []
            guard literals.isEmpty == false else { continue }

            values[property.uri] = literals.map { literal in
                guard property.searchType != nil, let uri = literal.string else { return .literal(literal) }
                return .entity(.init(uri: uri, label: labels[uri] ?? uri))
            }
        }
        self.init(values: values)
    }

    // MARK: - Reading

    func values(of property: EditionProperty) -> [EditionClaimValue] {
        values[property.uri] ?? []
    }

    func entities(of property: EditionProperty) -> [EditionEntityValue] {
        values(of: property).compactMap(\.entity)
    }

    /// The value of a single-valued literal property: a date, a count, a format.
    func literal(of property: EditionProperty) -> ClaimLiteral? {
        values(of: property).first?.claim
    }

    /// Every entity uri the values name, for the call that fetches their labels.
    var entityUris: [String] {
        EditionProperty.all.flatMap { entities(of: $0).compactMap(\.uri) }
    }

    /// The entities still to be created, in the order the save creates them: people and
    /// publishers first, collections last — a collection is created with its publisher's uri.
    var pendingEntities: [(property: EditionProperty, entity: EditionEntityValue)] {
        let pending: [(property: EditionProperty, entity: EditionEntityValue)] = EditionProperty.all.flatMap { property in
            entities(of: property).filter { $0.uri == nil }.map { (property: property, entity: $0) }
        }
        return pending.filter { $0.property != .collection } + pending.filter { $0.property == .collection }
    }

    /// The publisher a new collection is created under: the edition's first one that exists.
    var publisherUri: String? {
        entities(of: .publisher).lazy.compactMap(\.uri).first
    }

    /// The claims as they go on the wire, keyed by property uri. An entity still to be created is
    /// left out: it has no uri yet.
    var claims: [String: [ClaimLiteral]] {
        var claims: [String: [ClaimLiteral]] = [:]
        for property in EditionProperty.all {
            let literals: [ClaimLiteral] = values(of: property).compactMap(\.claim)
            if literals.isEmpty == false { claims[property.uri] = literals }
        }
        return claims
    }

    // MARK: - Changing

    /// Sets a single-valued literal: a date, a count, a format. `nil` takes it away.
    mutating func setLiteral(_ literal: ClaimLiteral?, for property: EditionProperty) {
        values[property.uri] = literal.map { [.literal($0)] }
    }

    /// Adds a literal to a multivalued property — an identifier, a link — unless it is there.
    mutating func addLiteral(_ literal: ClaimLiteral, to property: EditionProperty) {
        var current: [EditionClaimValue] = values(of: property)
        guard current.contains(where: { $0.claim == literal }) == false else { return }
        current.append(.literal(literal))
        values[property.uri] = property.isMultivalued ? current : [.literal(literal)]
    }

    /// Adds an entity, unless it is named already.
    mutating func add(_ entity: EditionEntityValue, to property: EditionProperty) {
        guard entity.trimmedLabel.isEmpty == false || entity.uri != nil else { return }
        var current: [EditionClaimValue] = values(of: property)
        guard current.contains(where: { $0.entity?.isSame(as: entity) == true }) == false else { return }
        current.append(.entity(entity))
        values[property.uri] = property.isMultivalued ? current : [.entity(entity)]
    }

    /// What a swipe on the values of a property takes away.
    mutating func remove(atOffsets offsets: IndexSet, from property: EditionProperty) {
        var current: [EditionClaimValue] = values(of: property)
        for index in offsets.sorted(by: >) where current.indices.contains(index) {
            current.remove(at: index)
        }
        values[property.uri] = current.isEmpty ? nil : current
    }

    /// Records the uri an entity was created under: the claim that names it can go now.
    mutating func entityCreated(id: UUID, uri: String) {
        for (key, current) in values {
            values[key] = current.map { value in
                guard case .entity(var entity) = value, entity.id == id else { return value }
                entity.uri = uri
                return .entity(entity)
            }
        }
    }

    // MARK: - What there is to send

    /// The claim updates that turn `original` into these values, on the entity `uri`. Entities
    /// still to be created are not listed until they exist.
    func updates(since original: EditionProperties, on uri: String) -> [EditionClaimUpdate] {
        var updates: [EditionClaimUpdate] = []
        for property in EditionProperty.all {
            let before: [ClaimLiteral] = original.values(of: property).compactMap(\.claim)
            let after: [ClaimLiteral] = values(of: property).compactMap(\.claim)

            if property.isMultivalued {
                for removed in before where after.contains(removed) == false {
                    updates.append(.init(uri: uri, property: property.uri, oldValue: removed, newValue: nil))
                }
                for added in after where before.contains(added) == false {
                    updates.append(.init(uri: uri, property: property.uri, oldValue: nil, newValue: added))
                }
            } else if before.first != after.first {
                updates.append(.init(uri: uri, property: property.uri, oldValue: before.first, newValue: after.first))
            }
        }
        return updates
    }

    /// Records that `update` landed on the server, so it drops out of `updates(since:on:)`. The
    /// value added is taken from `current`, which holds its name.
    mutating func apply(_ update: EditionClaimUpdate, from current: EditionProperties) {
        guard let property = EditionProperty.named(update.property) else { return }
        var values: [EditionClaimValue] = values(of: property)

        if let old = update.oldValue {
            values.removeAll { $0.claim == old }
        }
        if let new = update.newValue {
            let named: EditionClaimValue = current.values(of: property).first { $0.claim == new } ?? .literal(new)
            if property.isMultivalued {
                values.append(named)
            } else {
                values = [named]
            }
        }
        self.values[property.uri] = values.isEmpty ? nil : values
    }

    /// Whether the values differ from `original` in a way the save has to send or create.
    func differs(from original: EditionProperties) -> Bool {
        pendingEntities.isEmpty == false || updates(since: original, on: "").isEmpty == false
    }
}
