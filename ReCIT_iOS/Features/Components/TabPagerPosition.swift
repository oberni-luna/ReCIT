//
//  TabPagerPosition.swift
//  ReCIT_iOS
//
//  A `TabPager`'s position and nothing else, for a screen whose pages need no more than their
//  tabs to follow the swipe — a list's. A screen under a folding header keeps it in
//  `FoldingHeaderScrollOffset`, with the pages' scrolls the header folds by.
//

import CoreGraphics
import Observation

@MainActor
@Observable
final class TabPagerPosition: TabPagerPositionStore {
    var pagePosition: CGFloat = 0
}
