//
//  NetworkFriendNode.swift
//  ReCIT_iOS
//
//  A reader in the Réseau graph — `Graph / Friend` (`512:16016`): the 44 pt avatar, initials
//  when there is no picture (Q21), and the handle under it on one line, cut when it is long
//  (Q19). A reader who asked to be my friend has a dashed ring instead of the hairline (Q5b).
//
//  Its anchor — where the lines meet — is the centre of the avatar, not of the node: the name
//  hangs under it, on `backgroundDefault`, so a line from the avatar to a group below — or any other
//  line passing by — goes under the name instead of through it.
//
//  **Lit** by a touch — the reader touched, or a friend of the group touched — the ring turns to
//  2 pt of green and the name to bold (`Graph / Friend · Highlighted`, R2). The node keeps the
//  size it was measured at: the name is laid out in both weights and takes the room of the wider,
//  so lighting a node never moves the graph around it.
//
//  Touched through the graph's own hit test (`GraphViewport.node(at:)`), not as a button; what
//  VoiceOver says of it is `NetworkGraphAccessibility`'s, set where it is placed.
//

import SwiftUI

struct NetworkFriendNode: View {
    let reader: NetworkReaderNode
    var isHighlighted: Bool = false

    @ScaledMetric(relativeTo: .footnote) private var nameMaxWidth: CGFloat = NetworkGraphMetrics.friendNameMaxWidth

    var body: some View {
        VStack(spacing: .xSmall) {
            AvatarThumbnail(
                .reader(username: reader.reader.username),
                imageUrl: reader.reader.pictureURL,
                side: NetworkGraphMetrics.friendSide
            )
            .overlay {
                NetworkFriendRing(state: reader.state, isHighlighted: isHighlighted)
            }

            NetworkNodeWidthLimit(maxWidth: nameMaxWidth) {
                ZStack {
                    name(.footnote200)
                        .opacity(isHighlighted ? 0 : 1)
                    name(.footnote200Bold)
                        .opacity(isHighlighted ? 1 : 0)
                }
            }
            // A line from the avatar to a group below runs under the name rather than through it.
            .background(DesignSystem.Color.backgroundDefault.color)
        }
    }

    private func name(_ style: DesignSystem.TextStyle) -> some View {
        Text(verbatim: reader.reader.username)
            .textStyle(style)
            .foregroundStyle(.foregroundDefault)
            .lineLimit(1)
    }
}

#Preview {
    HStack(alignment: .top, spacing: .large) {
        NetworkFriendNode(
            reader: .init(reader: .init(id: "1", username: "Camille"), state: .friend, isIsolated: false)
        )
        NetworkFriendNode(
            reader: .init(reader: .init(id: "4", username: "Inès"), state: .friend, isIsolated: false),
            isHighlighted: true
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
