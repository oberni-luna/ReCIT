//
//  NetworkReaderSummary.swift
//  ReCIT_iOS
//
//  What the sheet of a reader touched in the Réseau graph says (PRD 0019, Q27, Q27 bis): who they
//  are, since when they have been on inventaire.io, and « 1 groupe en commun : Club de
//  Belleville. »
//
//  A reader who asked to be my friend is answered from the sheet (issue 0108): it says what
//  answering does, in the words of their profile, instead of the groups in common.
//
//  Only the groups we both administer or belong to are in common: a group that invited me is lit
//  when the friend is touched, but not counted. No group in common, no line — a « 0 » would read
//  « 0 groupe » in French, where zero is singular.
//

import Foundation

nonisolated struct NetworkReaderSummary: Hashable, Sendable {
    let reader: NetworkGraphReader
    let state: NetworkReaderState
    /// When the account was opened, or `nil` when the server has not said.
    let memberSince: Date?
    /// How many groups we share.
    let commonGroupCount: Int
    /// The groups the sentence names, in the order of the ring.
    let commonGroupNames: NetworkNameList

    /// - Parameters:
    ///   - reader: The reader touched.
    ///   - commonGroups: The groups we both administer or belong to.
    init(
        reader: NetworkReaderNode,
        commonGroups: [NetworkGraphGroup]
    ) {
        self.reader = reader.reader
        state = reader.state
        memberSince = reader.reader.created.map { Date(timeIntervalSince1970: $0 / 1000) }
        let common: [NetworkGraphGroup] = commonGroups.filter(\.role.belongs)
        commonGroupCount = common.count
        commonGroupNames = .init(common.map(\.name))
    }

    /// The summary of `reader` in `graph`.
    init(
        reader: NetworkReaderNode,
        in graph: NetworkGraph
    ) {
        self.init(reader: reader, commonGroups: graph.commonGroups(of: reader.id))
    }

    /// Whether the sheet offers Accepter and Refuser: the reader asked to be my friend.
    var isRequest: Bool {
        state == .requested
    }

    /// Whether the sheet says what we share.
    var hasCommonGroups: Bool {
        commonGroupCount > 0
    }
}
