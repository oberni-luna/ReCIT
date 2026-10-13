//
//  NetworkView.swift
//  ReCIT_iOS
//
//  The Réseau tab — frames `A1` and `A2` of the `Réseau · Onglet & Groupes` Figma pass, and the
//  `R1′` chrome of `Réseau · Graphe`.
//
//  The network used to sit in the middle of the Profil, between the transactions and the
//  sign-out row, where an invitation pushed everything else down and nothing in the tab bar said
//  it had arrived. It now has a tab of its own, split by a segmented control: Tout, the whole
//  network drawn around me (PRD 0019, `DEBUG` only for now); Amis, which is what the Profil
//  carried, moved as it was; and Groupes, inventaire.io's other way of sharing books.
//
//  **One control, fixed above the three segments.** It used to be the first row of a list shared
//  by Amis and Groupes, so the large title collapsed with the scroll. The graph of Tout does not
//  scroll, so the control moved to a band inset under the title, the same for the three, and it
//  no longer jumps when the segment changes (Q14). Amis and Groupes are each a list of their own
//  under it, scrolling as before. See PRD 0016 and PRD 0019.
//
//  **The segment is remembered** (Q12): the tab reopens on the last one chosen, on Tout the very
//  first time.
//

import SwiftUI

struct NetworkView: View {
    @State private var path: NavigationPath = .init()
    @State private var isCreatingGroup: Bool = false
    /// The raw value of the last segment chosen; `nil` until one is. Kept raw so that a value
    /// this build does not know is read by `NetworkSegment.restored(from:)`, not dropped.
    @AppStorage(NetworkSegment.storageKey) private var storedSegment: String?

    private var segment: NetworkSegment {
        .restored(from: storedSegment)
    }

    var body: some View {
        NavigationStack(path: $path) {
            NetworkSegmentContent(
                segment: segment,
                path: $path
            ) {
                isCreatingGroup = true
            }
            .safeAreaInset(edge: .top, spacing: .zero) {
                NetworkSegmentBand(
                    selection: .init(
                        get: { segment },
                        set: { storedSegment = $0.rawValue }
                    )
                )
            }
            .navigationTitle("nav.network")
            .toolbar { toolbarContent }
            .navigationDestination(for: NavigationDestination.self) { destination in
                destination.viewForDestination($path)
            }
            .sheet(isPresented: $isCreatingGroup) {
                CreateGroupView { groupId in
                    path.append(NavigationDestination.group(id: groupId))
                }
            }
        }
    }

    /// The « + » follows the segment: a friend to find on one side, a group on the other, and on
    /// Tout — which favours neither — a menu of both (Q15).
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            switch segment {
            #if DEBUG
            case .all:
                // A native menu, anchored under the « + » with no veil over the screen (Q15 ter).
                Menu("action.add", systemImage: "plus") {
                    Button("network.add_friends", systemImage: "person.badge.plus") {
                        path.append(NavigationDestination.addFriends)
                    }
                    .accessibilityIdentifier("e2e.network.menu.addFriends")

                    Button("groups.create", systemImage: "person.2") {
                        isCreatingGroup = true
                    }
                    .accessibilityIdentifier("e2e.network.menu.createGroup")
                }
                .accessibilityIdentifier("e2e.network.menu")
            #endif
            case .friends:
                Button("network.add_friends", systemImage: "plus") {
                    path.append(NavigationDestination.addFriends)
                }
                .accessibilityIdentifier("e2e.network.add")
            case .groups:
                Button("groups.create", systemImage: "plus") {
                    isCreatingGroup = true
                }
                .accessibilityIdentifier("e2e.network.createGroup")
            }
        }
    }
}
