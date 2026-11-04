//
//  ListRowView.swift
//  ReCIT_iOS
//
//  One list in the Lists tab: its first covers fanned out, then a line saying how many works or
//  authors it holds — headed, for a friend's list, by its maker's picture and name —, its name,
//  and what it is for. The name alone said nothing of what was inside.
//

import SwiftUI

struct ListRowView: View {
    let list: EntityList
    /// Who made the list, when it is not mine: « Dans mon réseau » in the Lists tab.
    var owner: User?

    var body: some View {
        if list.isStillInTheStore {
            HStack(spacing: .sMedium) {
                ListCoverFan(
                    uris: ListCoverPreview.uris(of: list.elements),
                    type: list.type
                )

                VStack(alignment: .leading, spacing: .zero) {
                    ListRowMetaLine(
                        owner: owner,
                        count: list.type.countLabel(list.elements.count)
                    )

                    Text(list.name)
                        .textStyle(.content400Bold)
                        .foregroundStyle(.foregroundDefault)
                        .lineLimit(1)

                    if !list.explanation.isEmpty {
                        Text(list.explanation)
                            .textStyle(.content200)
                            .foregroundStyle(.foregroundSecondary)
                            .lineLimit(3)
                    }
                }
            }
            .accessibilityElement(children: .combine)
        }
    }
}
