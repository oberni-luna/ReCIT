//
//  ListDetailTabPicker.swift
//  ReCIT_iOS
//
//  Livres • 8 | Présentation, under a list's navigation bar: the labels of a reader's profile
//  (`UserProfileTabPicker`), the selected one in a glass capsule. Changed by a touch only — the
//  horizontal swipe belongs to the cover flow underneath — so the capsule glides from one word to
//  the other rather than following a pager.
//

import SwiftUI

struct ListDetailTabPicker: View {
    @Binding var selection: ListDetailTab
    let listType: EntityListType
    /// How many elements the list holds, for the first tab's label.
    let count: Int

    @Namespace private var capsule

    var body: some View {
        HStack(spacing: .zero) {
            ForEach(ListDetailTab.allCases, id: \.self) { tab in
                let isSelected: Bool = tab == selection
                Button {
                    withAnimation(.snappy) {
                        selection = tab
                    }
                } label: {
                    label(for: tab)
                        .textStyle(.action200)
                        .foregroundStyle(isSelected ? .foregroundDefault : .foregroundSecondary)
                        // At the largest text sizes, shrunk rather than wrapped or cut.
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .padding(.horizontal, .sMedium)
                        .padding(.vertical, .small)
                        .background {
                            if isSelected {
                                Color.clear
                                    .glassCapsule()
                                    .matchedGeometryEffect(id: "capsule", in: capsule)
                            }
                        }
                        .contentShape(.capsule)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .accessibilityElement(children: .contain)
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
    /// Pins the tabs just under the navigation bar, as if they were part of it: from iOS 26 a
    /// `safeAreaBar` the list fades out under with the bar's own soft scroll edge; before it an
    /// inset on the bars' material, reaching up under the navigation bar.
    @ViewBuilder
    func listDetailTabsBar<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        let tabs: some View = content()
            .frame(maxWidth: .infinity)
            .padding(.top, .xxSmall)
            .padding(.bottom, .small)
        if #available(iOS 26.0, *) {
            safeAreaBar(edge: .top) {
                tabs
            }
            .scrollEdgeEffectStyle(.soft, for: .top)
        } else {
            safeAreaInset(edge: .top, spacing: .zero) {
                tabs
                    .background {
                        Rectangle()
                            .fill(.bar)
                            .ignoresSafeArea(edges: .top)
                    }
            }
        }
    }
}
