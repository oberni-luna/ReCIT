//
//  ListRowView.swift
//  ReCIT_iOS
//
//  One list in the Lists tab: its first covers fanned out, then its name, what it is for,
//  and how many works or authors it holds. The name alone said nothing of what was inside.
//

import SwiftUI

struct ListRowView: View {
    let list: EntityList

    var body: some View {
        HStack(spacing: .sMedium) {
            ListCoverFan(
                uris: ListCoverPreview.uris(of: list.elements),
                type: list.type
            )

            VStack(alignment: .leading, spacing: .xxSmall) {
                Text(list.name)
                    .textStyle(.content400Bold)
                    .foregroundStyle(.foregroundDefault)
                    .lineLimit(1)

                if !list.explanation.isEmpty {
                    Text(list.explanation)
                        .textStyle(.content300)
                        .foregroundStyle(.foregroundSecondary)
                        .lineLimit(1)
                }

                Text(list.type.countLabel(list.elements.count))
                    .textStyle(.footnote200)
                    .foregroundStyle(.foregroundSecondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
