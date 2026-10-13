//
//  NetworkGraph.swift
//  ReCIT_iOS
//
//  My network as a graph — the nodes and the lines « Tout » draws, and what each of them is joined
//  to (PRD 0019, module 4).
//
//  **What is drawn.** « Vous »; the groups I administer or belong to, and those that invited me
//  (Q4); my friends and the readers who asked to be one (Q5). Never a request I sent, a request
//  to join I sent, or a member of my groups who is not my friend: they count in « N membres »
//  and nowhere else (Q8). A friend in two of my groups is one node with two lines.
//
//  **The lines.** « Vous » to each group — dashed for an invitation; « Vous » to each reader —
//  dashed for a request; a friend to each drawn group they administer or belong to, the
//  invitations included, since what is dashed is only what waits on *me* (Q7). A friend joined to
//  no group is **isolated**: drawn near « Vous », tied to me alone (Q6); a requester always is.
//
//  **The orders**, so that the same network is always told the same way: groups by role — admin,
//  member, invitation — then by name, which is the order of the ring, first on top, clockwise
//  (Q18); readers by handle; and the VoiceOver reading order of Q44.
//
//  Pure and `nonisolated`: built from a value snapshot, testable without a store, and handed to
//  the placement off the main actor. Every list is an array in a fixed order, never a set or a
//  dictionary walked: the placement reads them in order, and that order has to be the same in
//  every process.
//

import Foundation

nonisolated struct NetworkGraph: Hashable, Sendable {
    let me: NetworkGraphReader
    /// In the order of the ring: admin, member, invitation, each by name (Q18).
    let groups: [NetworkGraphGroup]
    /// Friends and requesters, each once, by handle.
    let readers: [NetworkReaderNode]
    /// « Vous » to each group, « Vous » to each reader, then each friend to their groups — group
    /// by group in the order of the ring.
    let edges: [NetworkEdge]
    /// What « N amis · N groupes » says (Q10).
    let counter: NetworkGraphCounter

    private let groupIndex: [String: Int]
    private let readerIndex: [String: Int]
    /// For each reader, the indices in `groups` of the groups they administer or belong to.
    private let groupsOfReader: [[Int]]
    /// For each group, the indices in `readers` of my friends who administer it or belong to it.
    private let friendsOfGroup: [[Int]]

    init(_ input: NetworkGraphInput) {
        me = input.me

        var seenGroups: Set<String> = []
        let groups: [NetworkGraphGroup] = input.groups
            .filter { seenGroups.insert($0.id).inserted }
            .sorted(by: Self.ringOrder)
        self.groups = groups

        // A reader is a friend or a requester, never both, and never me.
        var seenReaders: Set<String> = [input.me.id]
        let friends: [NetworkGraphReader] = input.friends.filter { seenReaders.insert($0.id).inserted }
        let requesters: [NetworkGraphReader] = input.requesters.filter { seenReaders.insert($0.id).inserted }
        let friendIds: Set<String> = Set(friends.map(\.id))

        // Who is in which group: friends only, admins and members only (Q7).
        var groupsByFriend: [String: [Int]] = [:]
        for (index, group) in groups.enumerated() {
            var seenMembers: Set<String> = []
            for memberId in group.memberIds where friendIds.contains(memberId) && seenMembers.insert(memberId).inserted {
                groupsByFriend[memberId, default: []].append(index)
            }
        }

        let readers: [NetworkReaderNode] = (
            friends.map {
                NetworkReaderNode(
                    reader: $0,
                    state: .friend,
                    isIsolated: groupsByFriend[$0.id] == nil
                )
            }
            + requesters.map {
                NetworkReaderNode(reader: $0, state: .requested, isIsolated: true)
            }
        )
        .sorted { Self.readerOrder($0.reader, $1.reader) }
        self.readers = readers

        var readerIndex: [String: Int] = [:]
        for (index, reader) in readers.enumerated() {
            readerIndex[reader.id] = index
        }
        var groupIndex: [String: Int] = [:]
        for (index, group) in groups.enumerated() {
            groupIndex[group.id] = index
        }
        self.readerIndex = readerIndex
        self.groupIndex = groupIndex

        let groupsOfReader: [[Int]] = readers.map { reader in
            reader.state == .friend ? groupsByFriend[reader.id] ?? [] : []
        }
        var friendsOfGroup: [[Int]] = Array(repeating: [], count: groups.count)
        for (readerOffset, groupOffsets) in groupsOfReader.enumerated() {
            for groupOffset in groupOffsets {
                friendsOfGroup[groupOffset].append(readerOffset)
            }
        }
        self.groupsOfReader = groupsOfReader
        self.friendsOfGroup = friendsOfGroup

        var edges: [NetworkEdge] = groups.map { group in
            NetworkEdge(
                from: .me,
                to: .group(group.id),
                kind: group.role == .invited ? .meToInvitation : .meToGroup
            )
        }
        edges += readers.map { reader in
            NetworkEdge(
                from: .me,
                to: reader.nodeID,
                kind: reader.state == .requested ? .meToRequester : .meToFriend
            )
        }
        for (groupOffset, readerOffsets) in friendsOfGroup.enumerated() {
            edges += readerOffsets.map { readerOffset in
                NetworkEdge(
                    from: readers[readerOffset].nodeID,
                    to: .group(groups[groupOffset].id),
                    kind: .friendToGroup
                )
            }
        }
        self.edges = edges

        counter = .init(
            friends: friends.count,
            groups: groups.filter(\.role.belongs).count
        )
    }

    // MARK: - Nodes

    /// Every node: « Vous », the groups in the order of the ring, the readers by handle.
    var nodes: [NetworkNodeID] {
        [.me] + groups.map { .group($0.id) } + readers.map(\.nodeID)
    }

    /// Nobody and nothing around « Vous ».
    var isEmpty: Bool {
        groups.isEmpty && readers.isEmpty
    }

    func group(id: String) -> NetworkGraphGroup? {
        groupIndex[id].map { groups[$0] }
    }

    func reader(id: String) -> NetworkReaderNode? {
        readerIndex[id].map { readers[$0] }
    }

    /// Where in `groups` are the groups a reader is joined to by a line — what the placement
    /// pulls a friend towards. Empty for an isolated reader.
    func groupOffsets(of readerId: String) -> [Int] {
        readerIndex[readerId].map { groupsOfReader[$0] } ?? []
    }

    /// Whether `edge` is drawn at `level`. In the overview, the line from « Vous » to a friend
    /// goes, except for a friend tied to me alone — without it they would float — and a requester's
    /// dashed line stays (Q6, R3). Everything is drawn in full.
    func isDrawn(
        _ edge: NetworkEdge,
        at level: NetworkGraphLevel
    ) -> Bool {
        guard level == .overview, edge.kind == .meToFriend, case .reader(let id) = edge.to else { return true }

        return reader(id: id)?.isIsolated ?? true
    }

    // MARK: - Neighbours

    /// My friends who administer `groupId` or belong to it, by handle — what its sheet names.
    func friends(in groupId: String) -> [NetworkGraphReader] {
        guard let index = groupIndex[groupId] else { return [] }

        return friendsOfGroup[index].map { readers[$0].reader }
    }

    /// The groups I share with a friend: those we both administer or belong to — never an
    /// invitation, which is lit but not counted (Q27 bis). In the order of the ring.
    func commonGroups(of readerId: String) -> [NetworkGraphGroup] {
        groups(of: readerId).filter(\.role.belongs)
    }

    /// The groups that invited me and that a friend belongs to: lit when the friend is touched,
    /// not counted as in common (Q27 bis).
    func invitedGroups(of readerId: String) -> [NetworkGraphGroup] {
        groups(of: readerId).filter { $0.role == .invited }
    }

    /// What stays lit when `node` is touched: for a group, « Vous », the group, its friends and
    /// its lines (R2); for a reader, « Vous », the reader, their groups and their lines (Q27).
    /// `nil` for « Vous », which does nothing when touched (Q28), and for a node not drawn.
    func highlight(for node: NetworkNodeID) -> NetworkGraphHighlight? {
        let neighbours: [NetworkNodeID]
        switch node {
        case .me:
            return nil
        case .group(let id):
            guard groupIndex[id] != nil else { return nil }
            neighbours = friends(in: id).map { .reader($0.id) }
        case .reader(let id):
            guard readerIndex[id] != nil else { return nil }
            neighbours = groups(of: id).map { .group($0.id) }
        }
        return .init(
            nodes: Set([.me, node] + neighbours),
            edges: Set(edges.filter { $0.touches(node) })
        )
    }

    // MARK: - Reading order

    /// The order VoiceOver reads the graph in (Q44): « Vous », then what waits on my answer — the
    /// readers who asked, then the groups that invited me — then each of my groups in the order
    /// of the ring, then each friend once, by handle. Every node exactly once.
    var readingOrder: [NetworkNodeID] {
        let requesters: [NetworkNodeID] = readers.filter { $0.state == .requested }.map(\.nodeID)
        let invitations: [NetworkNodeID] = groups.filter { $0.role == .invited }.map { .group($0.id) }
        let mine: [NetworkNodeID] = groups.filter(\.role.belongs).map { .group($0.id) }
        let friends: [NetworkNodeID] = readers.filter { $0.state == .friend }.map(\.nodeID)
        return [.me] + requesters + invitations + mine + friends
    }

    // MARK: - Orders

    /// Admin, then member, then invitation; each by name as the Groupes list sorts it.
    private static func ringOrder(_ lhs: NetworkGraphGroup, _ rhs: NetworkGraphGroup) -> Bool {
        if lhs.role != rhs.role {
            return lhs.role < rhs.role
        }
        switch lhs.name.localizedStandardCompare(rhs.name) {
        case .orderedAscending: return true
        case .orderedDescending: return false
        case .orderedSame: return lhs.id < rhs.id
        }
    }

    private static func readerOrder(_ lhs: NetworkGraphReader, _ rhs: NetworkGraphReader) -> Bool {
        switch lhs.username.localizedStandardCompare(rhs.username) {
        case .orderedAscending: true
        case .orderedDescending: false
        case .orderedSame: lhs.id < rhs.id
        }
    }

    private func groups(of readerId: String) -> [NetworkGraphGroup] {
        groupOffsets(of: readerId).map { groups[$0] }
    }
}
