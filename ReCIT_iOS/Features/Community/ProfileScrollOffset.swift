//
//  ProfileScrollOffset.swift
//  ReCIT_iOS
//
//  Where a reader's profile pages are scrolled to, each counted from its rest, and where the
//  pager between them stands — written at every frame of a scroll or a swipe, and read by the
//  folding header alone. Held in an object rather than in the screen's state so that a scroll
//  redraws the header and nothing else: as `@State` of the screen, every frame re-evaluated the
//  whole page, books included, and the header stuttered as it unfolded.
//
//  The pages are passed in, in their order: a friend's profile has an Échanges page that mine
//  has not, so where a page stands depends on whose profile it is.
//

import Observation
import CoreGraphics

@MainActor
@Observable
final class ProfileScrollOffset: TabPagerPositionStore {
    /// Each page's scroll. A page never scrolled is at rest.
    private var offsets: [UserProfileTab: CGFloat] = [:]
    /// The pages whose scroll is idle — no finger on them, no deceleration, no bounce.
    private var busyPages: Set<UserProfileTab> = []
    /// Where the pager stands: 0 on the first page, 1 on the second, 2 on the third, in between
    /// during a swipe.
    var pagePosition: CGFloat = 0

    static func position(of page: UserProfileTab, among pages: [UserProfileTab]) -> CGFloat {
        CGFloat(pages.firstIndex(of: page) ?? 0)
    }

    /// Held between the first page and the last, which a bounce at either end would pass.
    static func clampedPosition(_ position: CGFloat, among pages: [UserProfileTab]) -> CGFloat {
        min(max(position, 0), CGFloat(max(pages.count - 1, 0)))
    }

    func offset(of page: UserProfileTab) -> CGFloat {
        offsets[page] ?? 0
    }

    func setOffset(_ offset: CGFloat, of page: UserProfileTab) {
        offsets[page] = offset
    }

    func setScrollIdle(_ isIdle: Bool, of page: UserProfileTab) {
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
    func isAtRest(_ page: UserProfileTab) -> Bool {
        busyPages.contains(page) == false && abs(offset(of: page)) < 0.5
    }

    /// At rest, with the pager settled on it: the header's fold is then the page's alone, the
    /// only moment the header may be measured.
    func isSettled(_ page: UserProfileTab, among pages: [UserProfileTab]) -> Bool {
        isAtRest(page) && abs(pagePosition - Self.position(of: page, among: pages)) < 0.001
    }

    /// How far the header has folded, blended between the two pages the pager stands between.
    func progress(in collapse: ProfileHeaderCollapse, among pages: [UserProfileTab]) -> CGFloat {
        collapse.progress(of: pages.map(offset(of:)), pagePosition: pagePosition)
    }

    /// How far the page on screen is pulled down past its top, blended the same way.
    func pull(among pages: [UserProfileTab]) -> CGFloat {
        ProfileHeaderCollapse.blend(
            pages.map { max(-offset(of: $0), 0) },
            at: pagePosition
        )
    }

    /// Whether the page that holds most of the screen has passed under the folded header.
    func isContentUnder(in collapse: ProfileHeaderCollapse, among pages: [UserProfileTab]) -> Bool {
        guard pages.isEmpty == false else { return false }
        let index: Int = min(max(Int(pagePosition.rounded()), 0), pages.count - 1)
        return collapse.isContentUnder(at: offset(of: pages[index]))
    }
}
