//
//  NetworkAllView.swift
//  ReCIT_iOS
//
//  Réseau › Tout — the segment that draws my network as a graph (PRD 0019), on
//  `backgroundDefault`, nav bar included, where the lists keep their grey (Q14).
//
//  **A shell for now** (issue 0105): « Vous » at the centre of the graph area, or the empty state
//  E1 when there is nobody and nothing to draw around me (Q39). The constellation — groups in a
//  ring, friends near the groups they share with me — fills the `.graph` case in issue 0106.
//
//  Everything is read from the store through `@Query` (ADR 0001), the groups included since issue
//  0103, so the segment is the same offline and from the moment the app opens.
//

import SwiftUI
import SwiftData

struct NetworkAllView: View {
    @Environment(UserModel.self) private var userModel
    @Environment(GroupModel.self) private var groupModel

    @Query private var allUsers: [User]
    @Query private var storedGroups: [StoredGroup]

    /// Me, as of the last sync — or, before the launch's first one and offline, my row in the
    /// store, found by the id `GroupModel` keeps across launches.
    private var signedInUser: User? {
        userModel.myUser ?? allUsers.first { $0._id == groupModel.myUserId }
    }

    var body: some View {
        let me: User? = signedInUser
        let content: NetworkAllContent = .init(
            relations: allUsers.lazy.filter { $0._id != me?._id }.map(\.relation),
            groups: groupModel.myGroups(from: storedGroups)
        )

        Group {
            switch content {
            case .empty:
                NetworkEmptyView(
                    username: me?.username ?? "",
                    imageUrl: me?.avatarURLValue
                )
            case .graph:
                // Centred on the avatar, as the constellation will be.
                MeCentredLayout(
                    spacing: .large,
                    leadAnchor: NetworkGraphMetrics.meSide / 2
                ) {
                    NetworkMeNode(
                        username: me?.username ?? "",
                        imageUrl: me?.avatarURLValue
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Through every safe area, so the band and the nav bar are white too. Not
        // `toolbarBackground`: it swaps the bar's appearance for one of SwiftUI's, which drops the
        // design system's title fonts — « Réseau » turned to the system font on this one segment.
        .background {
            DesignSystem.Color.backgroundDefault.color
                .ignoresSafeArea()
        }
    }
}
