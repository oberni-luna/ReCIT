//
//  NetworkGraphFixture.swift
//  ReCIT_iOSTests
//
//  The networks the Réseau graph suites are built from: R1 and R3 as the Figma screens draw them
//  (`603:20944`, `603:21890`), and a stress network of 200 friends and 30 groups (PRD 0019,
//  Q45) — plus boxes of a plausible size for each node, so the placement can be run without a
//  view to measure.
//

import CoreGraphics
import Foundation
@testable import ReCIT_iOS

nonisolated enum NetworkGraphFixture {

    // MARK: - R1

    /// R1′ — « Vous »; the Club de Belleville I administer, with requests waiting; BD & romans
    /// graphiques I belong to; the Lecteurs du 11e, who invited me through Camille; eight friends,
    /// Paul in none of my groups; and Ariane, who asked to be my friend.
    static var r1: NetworkGraphInput {
        let strangers: (String, Int) -> [String] = { prefix, count in
            (0..<count).map { "\(prefix)-stranger-\($0)" }
        }
        return .init(
            me: .init(id: "me", username: "olivier_berni"),
            friends: [
                reader("ines", "Inès"),
                reader("lea", "Léa"),
                reader("remi", "Rémi"),
                reader("camille", "Camille"),
                reader("hugo", "Hugo"),
                reader("sami", "Sami"),
                reader("nora", "Nora"),
                reader("paul", "Paul")
            ],
            requesters: [
                reader("ariane", "Ariane")
            ],
            groups: [
                .init(
                    id: "l11",
                    name: "Lecteurs du 11e",
                    role: .invited,
                    memberIds: ["camille", "nora"] + strangers("l11", 29),
                    invitorUsername: "Camille"
                ),
                .init(
                    id: "bd",
                    name: "BD & romans graphiques",
                    pictureURL: "https://inventaire.io/img/groups/bd",
                    role: .member,
                    memberIds: ["remi", "hugo", "sami", "me"] + strangers("bd", 44)
                ),
                .init(
                    id: "club",
                    name: "Club de Belleville",
                    pictureURL: "https://inventaire.io/img/groups/club",
                    role: .admin,
                    memberIds: ["me", "ines", "lea", "remi", "camille"] + strangers("club", 7),
                    pendingCount: 2
                )
            ]
        )
    }

    // MARK: - R3

    /// R3′ — 42 friends and 7 groups, one of them an invitation: 38 friends in one or two groups,
    /// 4 in none (Sarah, Nathan, Mila, Clara).
    static var r3: NetworkGraphInput {
        let groupNames: [String] = [
            "Club de Belleville",
            "BD & romans graphiques",
            "Classiques en VO",
            "Polar & noir",
            "SF & imaginaires",
            "Poésie du dimanche",
            "Lecteurs du 11e"
        ]
        let names: [String] = [
            "Inès", "Léa", "Rémi", "Camille", "Hugo", "Sami", "Julie", "Marc", "Aïcha", "Tom",
            "Zoé", "Yann", "Lina", "Omar", "Élise", "Bruno", "Chloé", "Karim", "Lucas", "Jade",
            "Adam", "Noé", "Eva", "Maya", "Hélène", "Gaspard", "Louise", "Arthur", "Manon", "Jules",
            "Rose", "Théo", "Alice", "Victor", "Anna", "Paul", "Nora", "Ariane",
            "Sarah", "Nathan", "Mila", "Clara"
        ]
        let friends: [NetworkGraphReader] = names.map { reader(slug($0), $0) }
        var members: [[String]] = Array(repeating: ["me"], count: groupNames.count)
        members[6] = []
        for (index, friend) in friends.prefix(38).enumerated() {
            members[index % 6].append(friend.id)
            if index % 3 == 0 {
                members[(index * 3 + 1) % 7].append(friend.id)
            }
        }
        let groups: [NetworkGraphGroup] = groupNames.enumerated().map { index, name in
            .init(
                id: slug(name),
                name: name,
                role: index == 6 ? .invited : (index == 0 ? .admin : .member),
                memberIds: members[index] + (0..<(5 + index)).map { "\(index)-stranger-\($0)" },
                invitorUsername: index == 6 ? "Camille" : nil
            )
        }
        return .init(
            me: .init(id: "me", username: "olivier_berni"),
            friends: friends,
            requesters: [],
            groups: groups
        )
    }

    // MARK: - Stress

    /// 200 friends and 30 groups — the budget of Q45 — with five requesters, three invitations,
    /// and every tenth friend in none of my groups.
    static var stress: NetworkGraphInput {
        let friends: [NetworkGraphReader] = (0..<200).map { reader("friend-\($0)", "Lecteur \($0)") }
        var members: [[String]] = Array(repeating: ["me"], count: 30)
        for (index, friend) in friends.enumerated() where index % 10 != 0 {
            members[index % 30].append(friend.id)
            if index % 4 == 0 {
                members[(index * 7 + 3) % 30].append(friend.id)
            }
        }
        let groups: [NetworkGraphGroup] = (0..<30).map { index in
            .init(
                id: "group-\(index)",
                name: "Groupe de lecture n° \(index)",
                role: index < 3 ? .admin : (index >= 27 ? .invited : .member),
                memberIds: members[index],
                invitorUsername: index >= 27 ? "Lecteur 1" : nil,
                pendingCount: index == 0 ? 3 : 0
            )
        }
        return .init(
            me: .init(id: "me", username: "olivier_berni"),
            friends: friends,
            requesters: (0..<5).map { reader("requester-\($0)", "Demandeur \($0)") },
            groups: groups
        )
    }

    // MARK: - Boxes

    /// A box of a plausible size for each node at the default text size: « Vous » as drawn,
    /// a reader as wide as its name up to the 100 pt column, a group card as wide as its name.
    static func boxes(for graph: NetworkGraph) -> [NetworkNodeID: NetworkNodeBox] {
        var boxes: [NetworkNodeID: NetworkNodeBox] = [
            .me: .init(size: .init(width: 72, height: 84), anchor: .init(x: 36, y: 36))
        ]
        for group in graph.groups {
            let width: CGFloat = min(32 + 8 + 8 + 12 + CGFloat(group.name.count) * 6.5, 220)
            boxes[.group(group.id)] = .init(centred: .init(width: width, height: 50))
        }
        for reader in graph.readers {
            let width: CGFloat = max(44, min(CGFloat(reader.reader.username.count) * 6.5, 100))
            boxes[reader.nodeID] = .init(
                size: .init(width: width, height: 63),
                anchor: .init(x: width / 2, y: 22)
            )
        }
        return boxes
    }

    /// The layout of `input` with the plausible boxes.
    static func layout(_ input: NetworkGraphInput) -> NetworkGraphLayout? {
        let graph: NetworkGraph = .init(input)
        return NetworkGraphLayout(graph: graph, boxes: boxes(for: graph))
    }

    // MARK: - Helpers

    static func reader(
        _ id: String,
        _ username: String
    ) -> NetworkGraphReader {
        .init(id: id, username: username)
    }

    private static func slug(_ name: String) -> String {
        name.lowercased().replacing(" ", with: "-")
    }
}
