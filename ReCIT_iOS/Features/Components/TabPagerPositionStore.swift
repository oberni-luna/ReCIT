//
//  TabPagerPositionStore.swift
//  ReCIT_iOS
//
//  Where a `TabPager` writes how far it stands between its pages: 0 on the first, 1 on the
//  second, in between during a swipe — at every frame of it, for a `LensTabPicker`'s capsule and,
//  on a reader's profile, the folding header to follow. An object rather than a binding, so a
//  swipe redraws what reads the position and not the screen that holds the pager.
//

import CoreGraphics

@MainActor
protocol TabPagerPositionStore: AnyObject {
    var pagePosition: CGFloat { get set }
}
