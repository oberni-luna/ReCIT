//
//  ListDetailTabPicker.swift
//  ReCIT_iOS
//
//  Livres • 8 | Présentation, under a list's navigation bar: a `LensTabPicker`, as on a reader's
//  profile. Its capsule follows the pager the two pages are in, and is picked up to slide from
//  one word to the other.
//
//  Reads the pager's position in its own body, so a swipe redraws the tabs and not the screen
//  that holds the pager — which would hand both pages a new view at every frame.
//

import SwiftUI

struct ListDetailTabPicker: View {
    @Binding var selection: ListDetailTab
    let position: TabPagerPosition
    let listType: EntityListType
    /// How many elements the list holds, for the first tab's label.
    let count: Int

    var body: some View {
        LensTabPicker(selection: $selection, pagePosition: position.pagePosition) { tab in
            label(for: tab)
        }
        .accessibilityLabel("list.tabs")
    }

    @ViewBuilder
    private func label(for tab: ListDetailTab) -> some View {
        switch tab {
        case .elements:
            switch listType {
            case .author:
                Text("list.tab.authors \(count)")
                    .accessibilityLabel(Text("list.tab.authors.accessibility \(count)"))
            case .work, .publisher:
                Text("list.tab.works \(count)")
                    .accessibilityLabel(Text("list.tab.works.accessibility \(count)"))
            }
        case .presentation:
            Text("list.tab.presentation")
        }
    }
}

extension View {
    /// The tabs laid over a list's pages, just under the navigation bar, as if they were part of
    /// it. From iOS 26 on nothing behind them: each page's list fades out under its own soft
    /// scroll edge (`listDetailTabsRoom`). Before it the bars' material, reaching up under the
    /// navigation bar.
    @ViewBuilder
    func listDetailTabsBar() -> some View {
        let tabs: some View = frame(maxWidth: .infinity)
            .padding(.top, .xxSmall)
            .padding(.bottom, .small)
        if #available(iOS 26.0, *) {
            tabs
        } else {
            tabs
                .background {
                    Rectangle()
                        .fill(.bar)
                        .ignoresSafeArea(edges: .top)
                }
        }
    }

    /// The room a list's page leaves at its top for the tabs laid over it: an empty bar as tall
    /// as they are, which from iOS 26 has the list fade out under it with the bar's own soft
    /// scroll edge.
    @ViewBuilder
    func listDetailTabsRoom(height: CGFloat) -> some View {
        let room: some View = Color.clear
            .frame(height: height)
            .allowsHitTesting(false)
        if #available(iOS 26.0, *) {
            safeAreaBar(edge: .top) {
                room
            }
            .scrollEdgeEffectStyle(.soft, for: .top)
        } else {
            safeAreaInset(edge: .top, spacing: .zero) {
                room
            }
        }
    }
}
