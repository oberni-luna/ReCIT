//
//  NetworkReaderSheet.swift
//  ReCIT_iOS
//
//  The sheet of a reader touched in the Réseau graph (PRD 0019, Q27): their avatar and handle,
//  « Membre depuis mars 2021 » as the reader rows say it, « 1 groupe en commun : Club de
//  Belleville. » — admin and member groups only (Q27 bis) — and « Voir le profil », full width.
//
//  A reader who asked to be my friend (Q5, Q26, issue 0108) is answered here: in place of the
//  groups in common, the sentence their profile says of the request, then Accepter and Refuser
//  above « Voir le profil », which steps down to the secondary style so one gesture leads.
//  Accepted, the sheet stays up and reads as a friend's; refused, the reader leaves the graph and
//  the sheet closes with them.
//

import SwiftUI

struct NetworkReaderSheet: View {
    let summary: NetworkReaderSummary
    let onOpen: () -> Void
    /// Answers the request; only offered while the reader is asking.
    var onAnswer: (NetworkSheetAnswer) -> Void = { _ in }

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

            if let explanation = summary.explanationText() {
                Text(verbatim: explanation)
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else if let commonGroups = summary.commonGroupsText() {
                Text(verbatim: commonGroups)
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundSecondary)
            }

            if summary.isRequest {
                NetworkSheetAnswerButtons(onAnswer: onAnswer)
            }

            Button(action: onOpen) {
                Text("network.graph.view_profile")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(summary.isRequest ? .secondary() : .primary())
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

#Preview("Request") {
    NetworkReaderSheet(
        summary: .init(
            reader: .init(
                reader: .init(id: "ariane", username: "Ariane", created: 1_614_556_800_000),
                state: .requested,
                isIsolated: true
            ),
            commonGroups: []
        ),
        onOpen: {}
    )
    .padding()
}
