//
//  NetworkFriendNode.swift
//  ReCIT_iOS
//
//  A reader in the Réseau graph — `Graph / Friend` (`512:16016`): the 44 pt avatar, initials
//  when there is no picture (Q21), and the handle under it on one line, cut when it is long
//  (Q19). A reader who asked to be my friend has a dashed ring instead of the hairline (Q5b).
//
//  Its anchor — where the lines meet — is the centre of the avatar, not of the node: the name
//  hangs under it.
//
//  Not a button yet: touching a node comes with the sheets (issue 0107).
//

import SwiftUI

struct NetworkFriendNode: View {
    let reader: NetworkReaderNode

    @ScaledMetric(relativeTo: .footnote) private var nameMaxWidth: CGFloat = NetworkGraphMetrics.friendNameMaxWidth

    var body: some View {
        VStack(spacing: .xSmall) {
            AvatarThumbnail(
                .reader(username: reader.reader.username),
                imageUrl: reader.reader.pictureURL,
                side: NetworkGraphMetrics.friendSide
            )
            .overlay {
                NetworkFriendRing(state: reader.state)
            }

            NetworkNodeWidthLimit(maxWidth: nameMaxWidth) {
                Text(verbatim: reader.reader.username)
                    .textStyle(.footnote200)
                    .foregroundStyle(.foregroundDefault)
                    .lineLimit(1)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue(reader.state == .requested ? Text("network.invitation.received") : Text(verbatim: ""))
    }
}

#Preview {
    HStack(alignment: .top, spacing: .large) {
        NetworkFriendNode(
            reader: .init(reader: .init(id: "1", username: "Camille"), state: .friend, isIsolated: false)
        )
        NetworkFriendNode(
            reader: .init(reader: .init(id: "2", username: "Ariane"), state: .requested, isIsolated: true)
        )
        NetworkFriendNode(
            reader: .init(reader: .init(id: "3", username: "un_pseudonyme_bien_trop_long"), state: .friend, isIsolated: true)
        )
    }
    .padding()
}
