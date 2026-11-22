//
//  FoldingHeaderPage.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 22/11/2026.
//

import SwiftUI

/// One page under a folding header, as an inset grouped `List` of its own: room for the header,
/// then the page's content. The pages sit side by side in a pager, so a tab is changed by a swipe
/// as well as by its name, and the change slides a whole page in instead of having one list swap
/// its sections, which drew the rows sliding and fading under the header.
///
/// Each page scrolls its own way and tells `FoldingHeaderScrollOffset` where it is; the header,
/// laid over the pager, folds by the page on screen. What scrolls with a page has to be in it.
struct FoldingHeaderPage<Tab: Hashable, UnderHeader: View, Content: View>: View {
    private let layout: FoldingHeaderPageLayout<Tab>
    /// Rows of the header's own section, right under the room it takes.
    private let underHeader: UnderHeader
    private let content: Content
    /// Rows held to the readable width on a wide screen — unless the page lays them out in
    /// columns, which needs the whole width.
    private var holdsReadableWidth: Bool = true

    /// The scroll view's top inset the offset is counted from, which barely moves.
    @State private var scrollTopInset: CGFloat = 0
    /// Where the list's first row starts on screen at rest: the list puts some room of its own
    /// above its first section, which the first row gives back.
    ///
    /// **Read only while the page is still.** Read whenever the offset said "at rest", it raced
    /// the scroll: a row's new position could arrive before the offset saying the page had
    /// moved, so the first row grew or shrank by that frame's scroll — the page stood still while
    /// the header folded, or sat 40 pt low after a bounce, then jumped back. Read only once, it
    /// caught the screen before the navigation bar had set its insets, and the list rose under
    /// the header. So: whenever the page is at rest (`FoldingHeaderScrollOffset.isAtRest`), which
    /// holds through the screen's arrival and never during a gesture or a bounce.
    @State private var firstRowTop: CGFloat?

    init(
        _ layout: FoldingHeaderPageLayout<Tab>,
        @ViewBuilder content: () -> Content,
        @ViewBuilder underHeader: () -> UnderHeader
    ) {
        self.layout = layout
        self.content = content()
        self.underHeader = underHeader()
    }

    /// The list's own room above its first section, once both tops are known.
    private var listTopRoom: CGFloat {
        guard let headerTop = layout.headerTop, let firstRowTop else { return 0 }
        return firstRowTop - headerTop
    }

    var body: some View {
        List {
            Group {
                Section {
                    // The room the unfolded header takes, as the page's first row rather than a
                    // content margin: the scroll's insets are then the bars' alone, and the offset
                    // counts from the page at rest whatever the header measures.
                    Color.clear
                        .frame(height: max(layout.expandedHeaderHeight - listTopRoom, 0))
                        .onGeometryChange(for: CGFloat.self) { $0.frame(in: .global).minY } action: { top in
                            guard layout.scrollOffset.isAtRest(layout.page) else { return }
                            firstRowTop = top
                        }

                    underHeader
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                content
            }
            .textCase(nil)
        }
        .listStyle(.insetGrouped)
        .readableContentMargins(isEnabled: holdsReadableWidth)
        .environment(\.defaultMinListRowHeight, 0)
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.y + geometry.contentInsets.top
        } action: { _, offset in
            layout.scrollOffset.setOffset(offset, of: layout.page)
        }
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentInsets.top
        } action: { _, inset in
            scrollTopInset = inset
        }
        .onScrollPhaseChange { _, phase in
            layout.scrollOffset.setScrollIdle(phase == .idle, of: layout.page)
        }
        .scrollTargetBehavior(FoldingHeaderSnapBehavior(collapse: layout.collapse, topInset: scrollTopInset))
        .topScrollEdgeEffectHidden()
        .applyListBackground(.backgroundForm)
        // Frozen while a book is being picked off an étagère, so the slide moves the
        // selection and not the page — the same rule the inventory's own carousel follows.
        .scrollDisabled(layout.isFrozen)
    }
}

extension FoldingHeaderPage where UnderHeader == EmptyView {
    init(
        _ layout: FoldingHeaderPageLayout<Tab>,
        @ViewBuilder content: () -> Content
    ) {
        self.init(layout, content: content) {
            EmptyView()
        }
    }
}

extension FoldingHeaderPage {
    /// Rows held to the readable width on a wide screen, or given the whole width.
    func holdsReadableWidth(_ holdsReadableWidth: Bool = true) -> Self {
        var copy: Self = self
        copy.holdsReadableWidth = holdsReadableWidth
        return copy
    }
}

#Preview {
    FoldingHeaderPage(
        .init(
            page: 0,
            expandedHeaderHeight: 120,
            headerTop: nil,
            collapse: .init(distance: 80),
            scrollOffset: FoldingHeaderScrollOffset<Int>(),
            isFrozen: false
        )
    ) {
        Section {
            ForEach(1...30, id: \.self) { row in
                Text(verbatim: "Ligne \(row)")
            }
        }
    }
}
