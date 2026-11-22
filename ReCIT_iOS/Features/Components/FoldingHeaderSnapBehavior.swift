//
//  FoldingHeaderSnapBehavior.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 22/11/2026.
//

import SwiftUI

/// A page under a folding header never comes to rest with the header half folded: a scroll that
/// would end inside the fold is carried to whichever end is nearer (`FoldingHeaderCollapse`).
/// Anywhere else the scroll ends where it would have.
struct FoldingHeaderSnapBehavior: ScrollTargetBehavior {
    let collapse: FoldingHeaderCollapse
    /// The scroll view's top inset — bars and content margin — which the target's origin counts
    /// from, while the fold counts from the page at rest.
    let topInset: CGFloat

    func updateTarget(_ target: inout ScrollTarget, context: TargetContext) {
        let offset: CGFloat = target.rect.minY + topInset
        target.rect.origin.y = collapse.restingOffset(for: offset) - topInset
    }
}
