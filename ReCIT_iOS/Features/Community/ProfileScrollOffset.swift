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

import Observation
import CoreGraphics

@MainActor
@Observable
final class ProfileScrollOffset {
    /// Each page's scroll. A page never scrolled is at rest.
    private var offsets: [UserProfileTab: CGFloat] = [:]
    /// The pages whose scroll is idle — no finger on them, no deceleration, no bounce.
    private var busyPages: Set<UserProfileTab> = []
    /// Where the pager stands: 0 on the first page, 1 on the second, in between during a swipe.
    var pagePosition: CGFloat = 0

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
    func isSettled(_ page: UserProfileTab) -> Bool {
        isAtRest(page) && abs(pagePosition - Self.position(of: page)) < 0.001
    }

    /// How far the header has folded, blended between the two pages while the pager moves.
    func progress(in collapse: ProfileHeaderCollapse) -> CGFloat {
        collapse.progress(
            between: offset(of: .inventory),
            and: offset(of: .lists),
            pagePosition: pagePosition
        )
    }

    /// How far the page on screen is pulled down past its top, blended the same way.
    var pull: CGFloat {
        ProfileHeaderCollapse.interpolate(
            from: max(-offset(of: .inventory), 0),
            to: max(-offset(of: .lists), 0),
            progress: min(max(pagePosition, 0), 1)
        )
    }

    /// Whether the page that holds most of the screen has passed under the folded header.
    func isContentUnder(in collapse: ProfileHeaderCollapse) -> Bool {
        collapse.isContentUnder(at: offset(of: pagePosition < 0.5 ? .inventory : .lists))
    }

    static func position(of page: UserProfileTab) -> CGFloat {
        CGFloat(UserProfileTab.allCases.firstIndex(of: page) ?? 0)
    }
}
