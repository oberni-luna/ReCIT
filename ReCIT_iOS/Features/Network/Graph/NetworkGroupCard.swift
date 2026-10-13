//
//  NetworkGroupCard.swift
//  ReCIT_iOS
//
//  A group in the Réseau graph — `Graph / Group` (`512:16061`): its picture in a 32 pt tile, or
//  the `person.2` glyph (Q21); its name, with the red dot when requests wait on me as its admin
//  (Q22); and « Admin · 12 membres », « 48 membres » or « Invitation de Camille » (Q9).
//
//  The card says the role by its look as well: tinted for a group I administer, white with a
//  green hairline for one I belong to, white with a dashed border and a green detail for one that
//  invited me — the dash every invitation of the graph is drawn with (Q32).
//
//  Its anchor is its centre. Name and detail are cut on one line past a width that grows with the
//  text (Q19). Not a button yet: touching a node comes with the sheets (issue 0107).
//

import SwiftUI

struct NetworkGroupCard: View {
    let group: NetworkGraphGroup

    @ScaledMetric(relativeTo: .footnote) private var textMaxWidth: CGFloat = NetworkGraphMetrics.groupTextMaxWidth

    private var shape: RoundedRectangle {
        .rect(cornerRadius: .rounded)
    }

    var body: some View {
        HStack(spacing: .small) {
            AvatarThumbnail(
                .group,
                imageUrl: group.pictureURL,
                side: NetworkGraphMetrics.groupTileSide,
                fallbackFill: group.role == .admin ? .backgroundDefault : .backgroundTinted
            )

            NetworkNodeWidthLimit(maxWidth: textMaxWidth) {
                VStack(alignment: .leading, spacing: .zero) {
                    HStack(spacing: .xSmall) {
                        Text(verbatim: group.name)
                            .textStyle(.footnote200Bold)
                            .foregroundStyle(.foregroundDefault)
                            .lineLimit(1)
                            .layoutPriority(1)

                        if group.pendingCount > 0 {
                            PendingDot(count: group.pendingCount)
                        }
                    }

                    Text(verbatim: NetworkGroupCardDetail(group).text)
                        .textStyle(.caption200)
                        .foregroundStyle(detailColor)
                        .lineLimit(1)
                }
            }
        }
        .padding(NetworkGraphMetrics.groupCardInsets)
        .background(fill.color, in: shape)
        .overlay {
            NetworkGroupCardBorder(role: group.role)
        }
        .shadow(.light)
        .accessibilityElement(children: .combine)
    }

    private var fill: DesignSystem.Color {
        group.role == .admin ? .backgroundTinted : .backgroundDefault
    }

    private var detailColor: DesignSystem.Color {
        group.role == .invited ? .foregroundTinted : .foregroundSecondary
    }
}

#Preview {
    VStack(spacing: .large) {
        NetworkGroupCard(
            group: .init(id: "a", name: "Club de Belleville", role: .admin, memberIds: [], memberCount: 12, pendingCount: 2)
        )
        NetworkGroupCard(
            group: .init(id: "b", name: "BD & romans graphiques", role: .member, memberIds: [], memberCount: 48)
        )
        NetworkGroupCard(
            group: .init(id: "c", name: "Lecteurs du 11e", role: .invited, memberIds: [], memberCount: 31, invitorUsername: "Camille")
        )
        NetworkGroupCard(
            group: .init(id: "d", name: "Un nom de groupe vraiment beaucoup trop long pour la carte", role: .member, memberIds: [], memberCount: 3)
        )
    }
    .padding()
}
