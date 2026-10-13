//
//  NetworkSegmentContent.swift
//  ReCIT_iOS
//
//  What sits under the segmented control of the Réseau tab: the graph of « Tout » on white, or
//  the list of Amis or Groupes on the lists' grey, scrolling as they always have.
//
//  A view of its own rather than a `switch` in `NetworkView`, so the band `NetworkView` insets
//  above it is attached outside the switch: one control for the three segments, which keeps its
//  identity — and its sliding selection — when the segment changes.
//

import SwiftUI

struct NetworkSegmentContent: View {
    let segment: NetworkSegment
    @Binding var path: NavigationPath
    /// Opens the group creation form, which `NetworkView` presents.
    let onCreateGroup: () -> Void

    var body: some View {
        switch segment {
        #if DEBUG
        case .all:
            NetworkAllView()
        #endif
        case .friends:
            List {
                FriendsSegmentView(path: $path)
            }
            .applyListBackground()
        case .groups:
            List {
                GroupsSegmentView(path: $path, onCreate: onCreateGroup)
            }
            .applyListBackground()
        }
    }
}
