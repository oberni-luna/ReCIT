//
//  NetworkGraphAccessibility.swift
//  ReCIT_iOS
//
//  The Réseau graph as VoiceOver reads it (PRD 0019, stories 69–71, Q44): a list rather than a
//  picture. « Vous » as a heading; then what waits on my answer — the readers who asked, the
//  groups that invited me; then each of my groups, its label naming my friends in it; then each
//  friend once, by handle, their label naming the groups we share. The order is
//  `NetworkGraph.readingOrder`, in which the constellation lays out the frames VoiceOver reads
//  (`NetworkNodeAccessibilityFrame`).
//
//  The labels reuse the words of the cards and the sheets — role, « 12 membres », « Invitation de
//  Camille », « 2 demandes à examiner », « dont 4 de vos amis : … », « 1 groupe en commun : … »
//  — joined by commas, where VoiceOver pauses, rather than by the cards' middle dot, which it may
//  read aloud. The names follow the sheets' rule (Q29 bis): past four, three and « et N autres »;
//  each friend is read on their own further down anyway.
//
//  Built once per network (`NetworkGraphView` keeps it), since the constellation is re-evaluated
//  with every frame of a pan or a slide, and 230 nodes' worth of catalogue lookups have no place
//  in a frame (Q45).
//

import Foundation

struct NetworkGraphAccessibility: Hashable, Sendable {
    private let nodes: [NetworkNodeID: NetworkNodeAccessibility]

    /// Nothing known yet: every node silent until the graph is first described.
    init() {
        nodes = [:]
    }

    init(
        _ graph: NetworkGraph,
        bundle: Bundle = .main,
        locale: Locale = .current
    ) {
        var nodes: [NetworkNodeID: NetworkNodeAccessibility] = [:]
        for node in graph.readingOrder {
            nodes[node] = .init(
                label: Self.label(of: node, in: graph, bundle: bundle, locale: locale),
                actions: graph.actions(for: node),
                isHeader: node == .me
            )
        }
        self.nodes = nodes
    }

    subscript(node: NetworkNodeID) -> NetworkNodeAccessibility? {
        nodes[node]
    }

    // MARK: - Labels

    private static func label(
        of node: NetworkNodeID,
        in graph: NetworkGraph,
        bundle: Bundle,
        locale: Locale
    ) -> String {
        switch node {
        case .me:
            return String(localized: "network.graph.me", bundle: bundle, locale: locale)
        case .group(let id):
            guard let group = graph.group(id: id) else { return "" }

            return groupLabel(group, in: graph, bundle: bundle, locale: locale)
        case .reader(let id):
            guard let reader = graph.reader(id: id) else { return "" }

            return readerLabel(reader, in: graph, bundle: bundle, locale: locale)
        }
    }

    /// « Club de Belleville, Admin, 2 demandes à examiner, 12 membres, dont 4 de vos amis :
    /// Camille, Inès, Léa et Rémi. »; « Lecteurs du 11e, Invitation de Camille, 31 membres, … »;
    /// « BD & romans graphiques, 48 membres. » when no friend of mine is in it.
    private static func groupLabel(
        _ group: NetworkGraphGroup,
        in graph: NetworkGraph,
        bundle: Bundle,
        locale: Locale
    ) -> String {
        let summary: NetworkGroupSummary = .init(group: group, in: graph)
        var parts: [String] = [group.name]
        switch group.role {
        case .admin:
            parts.append(String(localized: "groups.role.admin", bundle: bundle, locale: locale))
        case .member:
            break
        case .invited:
            if let invitor = summary.invitor {
                parts.append(String(localized: "groups.invited_by \(invitor)", bundle: bundle, locale: locale))
            } else {
                parts.append(String(localized: "network.invitation.received", bundle: bundle, locale: locale))
            }
        }
        if group.pendingCount > 0 {
            parts.append(String(localized: "groups.requests.pending \(group.pendingCount)", bundle: bundle, locale: locale))
        }
        parts.append(String(localized: "groups.members_count \(group.memberCount)", bundle: bundle, locale: locale))
        let lead: String = parts.joined(separator: ", ")

        guard summary.namesFriends else {
            return String(localized: "network.graph.sheet.group_members \(lead)", bundle: bundle, locale: locale)
        }

        let names: String = summary.friendNames.text(bundle: bundle, locale: locale)
        return String(
            localized: "network.graph.sheet.group_friends \(lead) \(summary.friendCount) \(names)",
            bundle: bundle,
            locale: locale
        )
    }

    /// « Camille, 1 groupe en commun : Club de Belleville. »; « Paul » when we share none;
    /// « Ariane, Invitation reçue » for a reader asking to be my friend.
    private static func readerLabel(
        _ reader: NetworkReaderNode,
        in graph: NetworkGraph,
        bundle: Bundle,
        locale: Locale
    ) -> String {
        let summary: NetworkReaderSummary = .init(reader: reader, in: graph)
        var parts: [String] = [reader.reader.username]
        if summary.isRequest {
            parts.append(String(localized: "network.invitation.received", bundle: bundle, locale: locale))
        } else if let commonGroups = summary.commonGroupsText(bundle: bundle, locale: locale) {
            parts.append(commonGroups)
        }
        return parts.joined(separator: ", ")
    }
}
