//
//  NetworkReaderSheet.swift
//  ReCIT_iOS
//
//  The sheet of a reader touched in the Réseau graph (PRD 0019, Q27): their avatar and handle,
//  « Membre depuis mars 2021 » as the reader rows say it, « 1 groupe en commun : Club de
//  Belleville. » — admin and member groups only (Q27 bis) — and « Voir le profil », full width.
//
//  A reader who asked to be my friend shows the same sheet for now; Accepter / Refuser come with
//  issue 0108.
//

import SwiftUI

struct NetworkReaderSheet: View {
    let summary: NetworkReaderSummary
    let onOpen: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: .sMedium) {
            HStack(spacing: .sMedium) {
                AvatarThumbnail(
                    .reader(username: summary.reader.username),
                    imageUrl: summary.reader.pictureURL,
                    side: NetworkGraphMetrics.friendSide
                )

                Text(verbatim: summary.reader.username)
                    .textStyle(.title50)
                    .foregroundStyle(.foregroundDefault)
                    .accessibilityAddTraits(.isHeader)
            }

            if let memberSince = summary.memberSinceText() {
                Text(verbatim: memberSince)
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundSecondary)
            }

            if let commonGroups = summary.commonGroupsText() {
                Text(verbatim: commonGroups)
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundSecondary)
            }

            Button(action: onOpen) {
                Text("network.graph.view_profile")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.primary())
            .accessibilityIdentifier("e2e.network.graph.sheet.viewProfile")
        }
    }
}

#Preview {
    NetworkReaderSheet(
        summary: .init(
            reader: .init(
                reader: .init(id: "camille", username: "Camille", created: 1_614_556_800_000),
                state: .friend,
                isIsolated: false
            ),
            commonGroups: [.init(id: "club", name: "Club de Belleville", role: .admin, memberIds: [])]
        ),
        onOpen: {}
    )
    .padding()
}
