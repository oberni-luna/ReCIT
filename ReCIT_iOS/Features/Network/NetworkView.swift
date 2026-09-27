//
//  NetworkView.swift
//  ReCIT_iOS
//
//  The Réseau tab — frames `A1` and `A2` of the `Réseau · Onglet & Groupes` Figma pass.
//
//  The network used to sit in the middle of the Profil, between the transactions and the
//  sign-out row, where an invitation pushed everything else down and nothing in the tab bar said
//  it had arrived. It now has a tab of its own, split by a segmented control: Amis, which is what
//  the Profil carried, moved as it was; and Groupes, inventaire.io's other way of sharing books.
//
//  **One list, two sets of sections.** The picker is the list's first row rather than a bar
//  above it, so the large title still collapses with the scroll the way it does on every other
//  tab. See PRD 0016.
//

import SwiftUI

struct NetworkView: View {
    @State private var path: NavigationPath = .init()
    @State private var segment: NetworkSegment = .friends

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Section {
                    Picker("network.segment", selection: $segment) {
                        ForEach(NetworkSegment.allCases, id: \.self) { segment in
                            Text(segment.title)
                                .tag(segment)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .accessibilityIdentifier("e2e.network.segment")
                }
                .listRowBackground(Color.clear)
                .listRowInsets()

                switch segment {
                case .friends:
                    FriendsSegmentView(path: $path)
                case .groups:
                    GroupsSegmentView(path: $path)
                }
            }
            .applyListBackground()
            .navigationTitle("nav.network")
            .toolbar { toolbarContent }
            .navigationDestination(for: NavigationDestination.self) { destination in
                destination.viewForDestination($path)
            }
        }
    }

    /// The « + » follows the segment: a friend to find on one side, a group on the other.
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            switch segment {
            case .friends:
                Button("network.add_friends", systemImage: "plus") {
                    path.append(NavigationDestination.addFriends)
                }
                .accessibilityIdentifier("e2e.network.add")
            case .groups:
                EmptyView()
            }
        }
    }
}
