//
//  GroupsSegmentView.swift
//  ReCIT_iOS
//
//  Réseau › Groupes — frames `A2` and `A3`.
//

import SwiftUI

struct GroupsSegmentView: View {
    @Binding var path: NavigationPath

    var body: some View {
        Section {
            EmptyStateView(
                glyph: "person.2",
                title: "groups.empty.title",
                message: "groups.empty.message"
            )
            .padding(.vertical, .large)
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
}
