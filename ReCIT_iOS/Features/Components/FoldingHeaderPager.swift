//
//  FoldingHeaderPager.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 22/11/2026.
//

import SwiftUI

/// A screen shaped like the Contacts card of Messages: a header held at the top, under the
/// navigation bar, that folds into it as the page scrolls and never stays half folded, over pages
/// side by side in a `TabPager`. A single page goes without the pager.
///
/// Each page is a `FoldingHeaderPage`, an inset grouped `List` whose first row is as tall as the
/// unfolded header, which lies over them all. The page builder is handed the
/// `FoldingHeaderPageLayout` to build it with; the header builder, the
/// `FoldingHeaderScrollOffset` to fold by — read in the header's own body and nowhere else, so a
/// scroll redraws the header alone.
struct FoldingHeaderPager<Tab: CaseIterable & Hashable, Header: View, Page: View>: View {
    /// The pages' tabs, in their order — the ones the fold is blended between.
    private let tabs: [Tab]
    private let collapse: FoldingHeaderCollapse
    private let header: (FoldingHeaderScrollOffset<Tab>) -> Header
    private let page: (FoldingHeaderPageLayout<Tab>) -> Page
    private var isFrozen: Bool = false

    /// The pages' scroll and the pager's position — never read by this body, so a scroll
    /// redraws the header alone.
    @State private var scrollOffset: FoldingHeaderScrollOffset<Tab> = .init()
    /// The header's height unfolded — what the pages are pushed down by.
    @State private var expandedHeaderHeight: CGFloat = 0
    /// Where the header starts on screen at rest, read only while the page on screen is settled
    /// (see `FoldingHeaderPage.firstRowTop`).
    @State private var headerTop: CGFloat?

    @Binding private var selection: Tab

    init(
        selection: Binding<Tab>,
        tabs: [Tab],
        collapse: FoldingHeaderCollapse,
        @ViewBuilder header: @escaping (FoldingHeaderScrollOffset<Tab>) -> Header,
        @ViewBuilder page: @escaping (FoldingHeaderPageLayout<Tab>) -> Page
    ) {
        _selection = selection
        self.tabs = tabs
        self.collapse = collapse
        self.header = header
        self.page = page
    }

    var body: some View {
        pages
            .overlay(alignment: .top) {
                measuredHeader
            }
            // The header draws its own backdrop under the bar, once the page passes under it.
            .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
            .background {
                DesignSystem.Color.backgroundForm.color
                    .ignoresSafeArea()
            }
    }

    /// The pages side by side, a swipe or a tab's name apart.
    @ViewBuilder
    private var pages: some View {
        if tabs.count > 1 {
            TabPager(
                selection: $selection,
                tabs: tabs,
                isFrozen: isFrozen,
                position: scrollOffset
            ) { tab in
                page(layout(of: tab))
            }
            // Edge to edge, so the pages run under the bars as a list does; UIKit hands each
            // page the safe area, which its list keeps its rows clear of. The keyboard is left
            // to the pages, whose lists bring the focused field above it.
            .ignoresSafeArea(.container)
        } else if let tab = tabs.first {
            page(layout(of: tab))
        }
    }

    /// Under the navigation bar, in the safe area: an overlay of the pages, laid out where they
    /// would be had they not run past it.
    private var measuredHeader: some View {
        header(scrollOffset)
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frame in
                guard scrollOffset.isSettled(selection, among: tabs) else { return }
                headerTop = frame.minY
                expandedHeaderHeight = frame.height
            }
    }

    private func layout(of tab: Tab) -> FoldingHeaderPageLayout<Tab> {
        .init(
            page: tab,
            expandedHeaderHeight: expandedHeaderHeight,
            headerTop: headerTop,
            collapse: collapse,
            scrollOffset: scrollOffset,
            isFrozen: isFrozen
        )
    }
}

extension FoldingHeaderPager {
    /// Holds the pages still — while a book is being picked off an étagère, say.
    func frozen(_ isFrozen: Bool = true) -> Self {
        var copy: Self = self
        copy.isFrozen = isFrozen
        return copy
    }
}

#Preview {
    @Previewable @State var tab: Haptics.Notification = .success

    NavigationStack {
        FoldingHeaderPager(
            selection: $tab,
            tabs: Haptics.Notification.allCases,
            collapse: .init(distance: 80)
        ) { _ in
            Text(verbatim: "Ex-libris")
                .textStyle(.title200)
                .padding(.vertical, .large)
        } page: { layout in
            FoldingHeaderPage(layout) {
                Section {
                    ForEach(1...40, id: \.self) { row in
                        Text(verbatim: "\(layout.page.rawValue) \(row)")
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
