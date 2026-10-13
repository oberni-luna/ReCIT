//
//  NetworkGroupSheet.swift
//  ReCIT_iOS
//
//  The sheet of a group touched in the Réseau graph (`sheet · groupe`, `514:16113`, PRD 0019,
//  R2, Q29): its name; « Admin · 12 membres, dont 4 de vos amis : Inès, Léa, Rémi et Camille. »;
//  the avatars of those friends; and « Ouvrir le groupe », full width.
//
//  An invitation (Q26, issue 0108) opens on « Invitation de Camille · 31 membres, … » and is
//  answered here: Accepter and Refuser above « Ouvrir le groupe », which steps down to the
//  secondary style so one gesture leads. Accepted, the sheet stays up and reads as a member's;
//  refused, the group leaves the graph and the sheet closes with it.
//

import SwiftUI

struct NetworkGroupSheet: View {
    let summary: NetworkGroupSummary
    let onOpen: () -> Void
    /// Answers the invitation; only offered while the group is one.
    var onAnswer: (NetworkSheetAnswer) -> Void = { _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: .sMedium) {
            Text(verbatim: summary.name)
                .textStyle(.title50)
                .foregroundStyle(.foregroundDefault)
                .accessibilityAddTraits(.isHeader)

            Text(verbatim: summary.sentence())
                .textStyle(.content300)
                .foregroundStyle(.foregroundSecondary)

            if summary.avatars.isEmpty == false {
                NetworkSheetAvatars(readers: summary.avatars)
            }

            if summary.isInvitation {
                NetworkSheetAnswerButtons(onAnswer: onAnswer)
            }

            Button(action: onOpen) {
                Text("network.graph.open_group")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(summary.isInvitation ? .secondary() : .primary())
            .accessibilityIdentifier("e2e.network.graph.sheet.openGroup")
        }
    }
}

#Preview {
    NetworkGroupSheet(
        summary: .init(
            group: .init(id: "club", name: "Club de Belleville", role: .admin, memberIds: [], memberCount: 12),
            friends: ["Inès", "Léa", "Rémi", "Camille"].map { .init(id: $0, username: $0) }
        ),
        onOpen: {}
    )
    .padding()
}

#Preview("Invitation") {
    NetworkGroupSheet(
        summary: .init(
            group: .init(
                id: "l11",
                name: "Lecteurs du 11e",
                role: .invited,
                memberIds: [],
                memberCount: 31,
                invitorUsername: "Camille"
            ),
            friends: ["Camille", "Nora"].map { .init(id: $0, username: $0) }
        ),
        onOpen: {}
    )
    .padding()
}
