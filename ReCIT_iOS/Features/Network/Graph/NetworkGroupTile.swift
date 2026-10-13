//
//  NetworkGroupTile.swift
//  ReCIT_iOS
//
//  A group in the overview of the Réseau graph — `Graph / Group · Compact` (`519:16401`, R3): its
//  picture, or the `person.2` glyph, in a 52 pt tile edged in `backgroundTintedInverse`, and its
//  name under it on one line, cut past a width that grows with the text. No detail, and no look
//  per role: the dashed line from « Vous » is what says an invitation (R3). The red dot still
//  follows the name when requests wait on me as its admin (Q22).
//
//  **Selected** (Q25), the name takes the selected look of the full card: `foregroundInverse` on
//  `backgroundTintedInverse`. Otherwise it sits on `backgroundDefault`, so the lines that pass
//  under it do not cross it.
//
//  The tile's corners are the avatar's `.medium`, not Figma's 14, which no radius token holds.
//  Its anchor is the centre of the tile, not of the node: the name hangs under it.
//

import SwiftUI

struct NetworkGroupTile: View {
    let group: NetworkGraphGroup
    var isSelected: Bool = false

    @ScaledMetric(relativeTo: .footnote) private var nameMaxWidth: CGFloat = NetworkGraphMetrics.compactNameMaxWidth

    var body: some View {
        VStack(spacing: .xSmall) {
            AvatarThumbnail(
                .group,
                imageUrl: group.pictureURL,
                side: NetworkGraphMetrics.compactTileSide,
                fallbackFill: isSelected ? .backgroundDefault : .backgroundTinted
            )
            .overlay {
                RoundedRectangle(cornerRadius: .medium)
                    .strokeBorder(
                        DesignSystem.Color.backgroundTintedInverse.color,
                        lineWidth: NetworkGraphMetrics.compactTileBorderWidth
                    )
            }

            HStack(spacing: .xSmall) {
                NetworkNodeWidthLimit(maxWidth: nameMaxWidth) {
                    Text(verbatim: group.name)
                        .textStyle(.footnote200Bold)
                        .foregroundStyle(nameColor)
                        .lineLimit(1)
                }
                .padding(.horizontal, .xSmall)
                .background(nameBackground.color, in: .capsule)

                if group.pendingCount > 0 {
                    PendingDot(count: group.pendingCount)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var nameColor: DesignSystem.Color {
        isSelected ? .foregroundInverse : .foregroundDefault
    }

    private var nameBackground: DesignSystem.Color {
        isSelected ? .backgroundTintedInverse : .backgroundDefault
    }
}

#Preview {
    HStack(alignment: .top, spacing: .large) {
        NetworkGroupTile(
            group: .init(id: "a", name: "Club de Belleville", role: .admin, memberIds: [], memberCount: 12, pendingCount: 2)
        )
        NetworkGroupTile(
            group: .init(id: "b", name: "BD & romans graphiques", role: .member, memberIds: [], memberCount: 48),
            isSelected: true
        )
        NetworkGroupTile(
            group: .init(id: "c", name: "Polar", role: .invited, memberIds: [], memberCount: 31, invitorUsername: "Camille")
        )
    }
    .padding()
}
