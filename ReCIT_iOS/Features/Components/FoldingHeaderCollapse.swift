//
//  FoldingHeaderCollapse.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 22/11/2026.
//

import CoreGraphics

/// How far a folding header has folded, read off the scroll offset: on a reader's profile the
/// picture shrinks into the navigation bar, the name with it, and from there on the page scrolls
/// under a header that keeps its compact size. The way the Contacts card folds, in Messages.
///
/// Pure on purpose, like the shelf layout maths: the two rules worth a test — how far the fold
/// has gone, and where a scroll left halfway lands — need no screen to be checked.
struct FoldingHeaderCollapse: Equatable {
    /// How many points of scroll fold the header from its full size to its compact one.
    let distance: CGFloat

    /// One value per page, blended between the two pages the pager stands between: `values[0]`
    /// at 0, `values[1]` at 1, and so on. A position past either end holds the end's value.
    static func blend(_ values: [CGFloat], at pagePosition: CGFloat) -> CGFloat {
        guard let last = values.indices.last else { return 0 }
        let position: CGFloat = min(max(pagePosition, 0), CGFloat(last))
        let lower: Int = .init(position.rounded(.down))
        let upper: Int = min(lower + 1, last)
        return interpolate(from: values[lower], to: values[upper], progress: position - CGFloat(lower))
    }

    /// `from` at rest, `to` once folded.
    static func interpolate(from rest: CGFloat, to folded: CGFloat, progress: CGFloat) -> CGFloat {
        rest + (folded - rest) * progress
    }

    /// 0 at rest, 1 once folded. A pull past the top (a negative offset) is still at rest.
    func progress(at offset: CGFloat) -> CGFloat {
        guard distance > 0 else { return 0 }
        return min(max(offset / distance, 0), 1)
    }

    /// Whether the page has started to pass under the folded header — which is when the header
    /// needs a backdrop of its own, and not before: until then nothing is behind it.
    func isContentUnder(at offset: CGFloat) -> Bool {
        offset > distance
    }

    /// Where a scroll that ends inside the fold comes to rest: folded or unfolded, never caught
    /// halfway, on whichever side is nearer. Anywhere else is left where it is.
    func restingOffset(for offset: CGFloat) -> CGFloat {
        guard offset > 0, offset < distance else { return offset }
        return offset < distance / 2 ? 0 : distance
    }

    /// The room a page adds under its content so that it scrolls at least the whole fold: a page
    /// shorter than that ran out of rows with the header half folded, and could never land folded.
    /// A page long enough needs none.
    ///
    /// - Parameters:
    ///   - scrollRange: How far the page scrolls past its rest, `currentRoom` included.
    ///   - currentRoom: The room the page already adds.
    /// - Returns: The room that has the page scroll exactly the fold, or 0.
    func bottomRoom(
        scrollRange: CGFloat,
        currentRoom: CGFloat
    ) -> CGFloat {
        max(currentRoom + distance - scrollRange, 0)
    }

    /// The fold while the pager moves between pages, each scrolled its own way: the first page's
    /// at 0, the second's at 1, the third's at 2, and in between as much of the two pages the
    /// pager stands between as is on screen. The fold is what is blended, not the offsets —
    /// halfway from a page scrolled 2 000 pt down to one at rest is half folded, not still folded.
    func progress(of offsets: [CGFloat], pagePosition: CGFloat) -> CGFloat {
        Self.blend(offsets.map { progress(at: $0) }, at: pagePosition)
    }
}
