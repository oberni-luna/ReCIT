//
//  GroupCellView.swift
//  ReCIT_iOS
//
//  A group in a list — the left half of `Cell / Group` in the Figma pass. The picture is a
//  square with rounded corners where a reader's is a circle: a group should never be read as a
//  person at a glance.
//
//  A dot after the name says the group waits on me — requests to join that only I, as an admin,
//  can answer. It is what the Réseau tab's badge counts, put back on the group it came from.
//

import SwiftUI

struct GroupCellView: View {
    let name: String
    let pictureURL: String?
    /// The second line: how many people, or what the group says of itself.
    let detail: Text?
    /// How many answers the group waits on from me; a dot follows the name when there are any.
    let pendingCount: Int

    init(
        group: ReaderGroup,
        pendingCount: Int = 0
    ) {
        self.name = group.name
        self.pictureURL = group.pictureURL
        self.detail = Text("groups.members_count \(group.memberCount)")
        self.pendingCount = pendingCount
    }

    init(result: GroupSearchResult) {
        self.name = result.name
        self.pictureURL = result.pictureURL
        self.detail = result.description.flatMap { $0.isEmpty ? nil : Text($0) }
        self.pendingCount = 0
    }

    var body: some View {
        HStack(alignment: .top, spacing: .sMedium) {
            CellThumbnail(imageUrl: pictureURL, cornerRadius: .medium, size: .medium)

            VStack(alignment: .leading, spacing: .xSmall) {
                HStack(spacing: .small) {
                    Text(name)
                        .textStyle(.content400Bold)
                        .foregroundStyle(.foregroundDefault)

                    if pendingCount > 0 {
                        PendingDot(count: pendingCount)
                    }
                }

                if let detail {
                    detail
                        .textStyle(.content300)
                        .foregroundStyle(.foregroundDefault)
                        .lineLimit(2)
                }
            }
        }
    }
}
