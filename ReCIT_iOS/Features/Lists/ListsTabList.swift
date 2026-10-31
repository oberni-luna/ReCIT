//
//  ListsTabList.swift
//  ReCIT_iOS
//
//  The Lists tab once there is something to show: « Mes listes », then « Dans mon réseau ».
//
//  My rows are mine to delete with a swipe; a friend's open read-only (`EntityListDetail` knows
//  on its own) and swipe nothing. Without a list of my own while my friends have some, « Mes
//  listes » keeps one row, « Créer une liste », rather than going: the section says where mine
//  will go. The headers show only when there is a network to set mine apart from.
//

import SwiftUI

struct ListsTabList: View {
    let sections: ListsTabSections
    let showsHeaders: Bool
    let isSearching: Bool
    let onCreate: () -> Void
    let onDelete: (EntityList) -> Void

    var body: some View {
        List {
            if !sections.mine.isEmpty || (showsHeaders && !isSearching) {
                Section {
                    if sections.mine.isEmpty {
                        Button("lists.empty.action.create.title", systemImage: "plus", action: onCreate)
                            .textStyle(.content300)
                            .foregroundStyle(.foregroundTinted)
                            .accessibilityIdentifier("e2e.lists.create")
                    } else {
                        ForEach(sections.mine) { list in
                            NavigationLink(value: NavigationDestination.entityList(id: list._id)) {
                                ListRowView(list: list)
                                    .swipeActions {
                                        Button("action.delete", systemImage: "trash") {
                                            onDelete(list)
                                        }
                                        .tint(.red)
                                    }
                            }
                            .accessibilityIdentifier("e2e.listRow")
                        }
                    }
                } header: {
                    if showsHeaders {
                        Text("lists.section.mine")
                    }
                }
            }

            if !sections.network.isEmpty {
                Section("lists.section.network") {
                    ForEach(sections.network) { entry in
                        NavigationLink(value: NavigationDestination.entityList(id: entry.list._id)) {
                            ListRowView(list: entry.list, owner: entry.owner)
                        }
                        .accessibilityIdentifier("e2e.lists.networkRow")
                    }
                }
            }
        }
    }
}
