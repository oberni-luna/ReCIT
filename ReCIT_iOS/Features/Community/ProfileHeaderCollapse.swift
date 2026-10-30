//
//  ProfileHeaderCollapse.swift
//  ReCIT_iOS
//
//  How far a reader's profile header has folded, read off the scroll offset: the picture
//  shrinks into the navigation bar, the name with it, the book count goes, and from there on
//  the page scrolls under a header that keeps its compact size. The way the Contacts card
//  folds, in Messages.
//
//  Pure on purpose, like the shelf layout maths: the two rules worth a test — how far the fold
//  has gone, and where a scroll left halfway lands — need no screen to be checked.
//

import CoreGraphics

struct ProfileHeaderCollapse: Equatable {
    /// How many points of scroll fold the header from its full size to its compact one.
    let distance: CGFloat

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

    /// `from` at rest, `to` once folded.
    static func interpolate(from: CGFloat, to: CGFloat, progress: CGFloat) -> CGFloat {
        from + (to - from) * progress
    }
}
