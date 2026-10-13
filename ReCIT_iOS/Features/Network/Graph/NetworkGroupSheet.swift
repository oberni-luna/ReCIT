//
//  NetworkGroupSheet.swift
//  ReCIT_iOS
//
//  The sheet of a group touched in the Réseau graph (`sheet · groupe`, `514:16113`, PRD 0019,
//  R2, Q29): its name; « Admin · 12 membres, dont 4 de vos amis : Inès, Léa, Rémi et Camille. »;
//  the avatars of those friends; and « Ouvrir le groupe », full width.
//
//  An invitation shows the same sheet for now; its Accepter / Refuser come with issue 0108.
//

import SwiftUI

struct NetworkGroupSheet: View {
    let summary: NetworkGroupSummary
    let onOpen: () -> Void

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

            Button(action: onOpen) {
                Text("network.graph.open_group")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.primary())
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
