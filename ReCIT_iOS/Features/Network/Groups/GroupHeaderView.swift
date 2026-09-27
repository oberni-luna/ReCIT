//
//  GroupHeaderView.swift
//  ReCIT_iOS
//
//  The top of a group's screen — `Group Header`: its picture, its name, what it says of itself,
//  and two facts in tags, who may come in and how many are there. Cousin of `UserHeaderView`,
//  with the same padding and the same name style.
//

import SwiftUI

struct GroupHeaderView: View {
    let group: ReaderGroup

    @State private var isDescriptionExpanded: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: .small) {
            CellThumbnail(imageUrl: group.pictureURL, cornerRadius: .medium, size: .large)

            Text(group.name)
                .textStyle(.content400Bold)
                .foregroundStyle(.foregroundDefault)

            if group.description.isEmpty == false {
                // Up to 5000 characters on the server: four lines, and the rest on a tap.
                Button {
                    withAnimation {
                        isDescriptionExpanded.toggle()
                    }
                } label: {
                    Text(group.description)
                        .textStyle(.content300)
                        .foregroundStyle(.foregroundDefault)
                        .multilineTextAlignment(.leading)
                        .lineLimit(isDescriptionExpanded ? nil : 4)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: .small) {
                Label(
                    group.open ? "groups.access.open" : "groups.access.on_request",
                    systemImage: group.open ? "door.left.hand.open" : "lock"
                )
                .labelStyle(.secondaryTag)

                Label("groups.members_count \(group.memberCount)", systemImage: "person.2")
                    .labelStyle(.secondaryTag)
            }
        }
        .padding(.vertical, .small)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
