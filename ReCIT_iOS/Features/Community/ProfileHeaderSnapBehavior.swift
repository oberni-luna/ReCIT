//
//  ProfileHeaderSnapBehavior.swift
//  ReCIT_iOS
//
//  A reader's profile never comes to rest with its header half folded: a scroll that would end
//  inside the fold is carried to whichever end is nearer (`ProfileHeaderCollapse`). Anywhere
//  else the scroll ends where it would have.
//

import SwiftUI

struct ProfileHeaderSnapBehavior: ScrollTargetBehavior {
    let collapse: ProfileHeaderCollapse
    /// The scroll view's top inset — bars and content margin — which the target's origin counts
    /// from, while the fold counts from the page at rest.
    let topInset: CGFloat

    func updateTarget(_ target: inout ScrollTarget, context: TargetContext) {
        let offset: CGFloat = target.rect.minY + topInset
        target.rect.origin.y = collapse.restingOffset(for: offset) - topInset
    }
}
