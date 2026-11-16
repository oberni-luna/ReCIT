//
//  SearchGroupRow.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 16/11/2026.
//

import SwiftData
import SwiftUI

/// A group of mine found by Recherche, drawn as in Réseau › Groupes. Opens the group's screen.
struct SearchGroupRow: View {
    private let group: ReaderGroup

    @Environment(GroupModel.self) private var groupModel: GroupModel

    init(_ group: ReaderGroup) {
        self.group = group
    }

    var body: some View {
        NavigationLink(value: NavigationDestination.group(id: group.id)) {
            GroupRowView(
                cell: .init(
                    group: group,
                    pendingCount: group.requestsToReview(by: groupModel.myUserId)
                ),
                role: group.role(of: groupModel.myUserId)
            )
        }
        .accessibilityIdentifier(AccessibilityID.row)
    }
}

private extension SearchGroupRow {
    enum AccessibilityID {
        static let row: String = "e2e.searchGroup"
    }
}

#Preview(traits: .modifier(SearchLocalPreviewStore())) {
    @Previewable @Query(sort: \StoredGroup.name) var groups: [StoredGroup]
    NavigationStack {
        List {
            ForEach(groups.map(\.readerGroup)) { group in
                SearchGroupRow(group)
            }
        }
    }
}
