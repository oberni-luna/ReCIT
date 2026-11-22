//
//  FoldingHeaderScrollOffset.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 22/11/2026.
//

import CoreGraphics
import Observation

/// Where the pages under a folding header are scrolled to, each counted from its rest, and where
/// the pager between them stands — written at every frame of a scroll or a swipe, and read by the
/// folding header alone. Held in an object rather than in the screen's state so that a scroll
/// redraws the header and nothing else: as `@State` of the screen, every frame re-evaluated the
/// whole page, books included, and the header stuttered as it unfolded.
///
/// The pages are passed in, in their order: a friend's profile has an Échanges page that mine
/// has not, so where a page stands depends on whose profile it is.
@MainActor
@Observable
final class FoldingHeaderScrollOffset<Tab: Hashable>: TabPagerPositionStore {
    /// Where the pager stands: 0 on the first page, 1 on the second, 2 on the third, in between
    /// during a swipe.
    var pagePosition: CGFloat = 0
    /// Each page's scroll. A page never scrolled is at rest.
    private var offsets: [Tab: CGFloat] = [:]
    /// The pages whose scroll is busy — a finger on them, a deceleration, a bounce.
    private var busyPages: Set<Tab> = []

    static func position(of page: Tab, among pages: [Tab]) -> CGFloat {
        CGFloat(pages.firstIndex(of: page) ?? 0)
    }

    /// Held between the first page and the last, which a bounce at either end would pass.
    static func clampedPosition(_ position: CGFloat, among pages: [Tab]) -> CGFloat {
        min(max(position, 0), CGFloat(max(pages.count - 1, 0)))
    }

    func offset(of page: Tab) -> CGFloat {
        offsets[page] ?? 0
    }

    func setOffset(_ offset: CGFloat, of page: Tab) {
        offsets[page] = offset
    }

    func setScrollIdle(_ isIdle: Bool, of page: Tab) {
        if isIdle {
            busyPages.remove(page)
        } else {
            busyPages.insert(page)
        }
    }

    /// Still, exactly at rest — not folding, not pulled down past the top: the only moment a
    /// page's own rows may be measured. Where the pager stands does not matter to them — a swipe
    /// moves a page sideways, never up or down — and a page first drawn mid-swipe has to be
    /// measured then, since nothing moves it again once the swipe ends.
    func isAtRest(_ page: Tab) -> Bool {
        busyPages.contains(page) == false && abs(offset(of: page)) < 0.5
    }

    /// At rest, with the pager settled on it: the header's fold is then the page's alone, the
    /// only moment the header may be measured.
    func isSettled(_ page: Tab, among pages: [Tab]) -> Bool {
        isAtRest(page) && abs(pagePosition - Self.position(of: page, among: pages)) < 0.001
    }

    /// How far the header has folded, blended between the two pages the pager stands between.
    func progress(in collapse: FoldingHeaderCollapse, among pages: [Tab]) -> CGFloat {
        collapse.progress(of: pages.map(offset(of:)), pagePosition: pagePosition)
    }

    /// How far the page on screen is pulled down past its top, blended the same way.
    func pull(among pages: [Tab]) -> CGFloat {
        FoldingHeaderCollapse.blend(
            pages.map { max(-offset(of: $0), 0) },
            at: pagePosition
        )
    }

    /// Whether the page that holds most of the screen has passed under the folded header.
    func isContentUnder(in collapse: FoldingHeaderCollapse, among pages: [Tab]) -> Bool {
        guard pages.isEmpty == false else { return false }
        let index: Int = min(max(Int(pagePosition.rounded()), 0), pages.count - 1)
        return collapse.isContentUnder(at: offset(of: pages[index]))
    }
}
