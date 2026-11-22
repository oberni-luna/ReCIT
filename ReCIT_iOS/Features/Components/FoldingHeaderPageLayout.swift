//
//  FoldingHeaderPageLayout.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 22/11/2026.
//

import CoreGraphics

/// What a page under a folding header is handed by the `FoldingHeaderPager` that holds it: which
/// page it is, the room the unfolded header takes, and where to tell its scroll.
struct FoldingHeaderPageLayout<Tab: Hashable> {
    let page: Tab
    /// The header's height unfolded — what the page is pushed down by.
    let expandedHeaderHeight: CGFloat
    /// Where the header starts on screen at rest.
    let headerTop: CGFloat?
    let collapse: FoldingHeaderCollapse
    /// Written by the page, read by the header alone — never by the page's body, so a scroll
    /// redraws the header only.
    let scrollOffset: FoldingHeaderScrollOffset<Tab>
    /// Holds the page still — while a book is being picked off an étagère, say.
    let isFrozen: Bool
}
