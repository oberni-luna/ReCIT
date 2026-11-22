//
//  FoldingHeaderCollapseTests.swift
//  ReCIT_iOSTests
//
//  Created by Olivier Berni on 22/11/2026.
//

import CoreGraphics
import Testing
@testable import ReCIT_iOS

@Suite
struct FoldingHeaderCollapseTests {
    private let collapse: FoldingHeaderCollapse = .init(distance: 100)

    @Test
    func `the fold follows the scroll, and stops at both ends`() {
        #expect(collapse.progress(at: -40) == 0)
        #expect(collapse.progress(at: 0) == 0)
        #expect(collapse.progress(at: 25) == 0.25)
        #expect(collapse.progress(at: 100) == 1)
        #expect(collapse.progress(at: 600) == 1)
        #expect(FoldingHeaderCollapse(distance: 0).progress(at: 50) == 0)
    }

    @Test
    @MainActor
    func `the pager's position is held between the first page and the last`() {
        let pages: [Int] = [0, 1, 2]
        #expect(FoldingHeaderScrollOffset.clampedPosition(-0.3, among: pages) == 0)
        #expect(FoldingHeaderScrollOffset.clampedPosition(1.6, among: pages) == 1.6)
        #expect(FoldingHeaderScrollOffset.clampedPosition(2.4, among: pages) == CGFloat(pages.count - 1))
    }

    @Test
    func `the page passes under the header only once it is folded`() {
        #expect(collapse.isContentUnder(at: 100) == false)
        #expect(collapse.isContentUnder(at: 101))
    }

    @Test
    func `a scroll left inside the fold lands on the nearer side, elsewhere it stays`() {
        #expect(collapse.restingOffset(for: 30) == 0)
        #expect(collapse.restingOffset(for: 50) == 100)
        #expect(collapse.restingOffset(for: 80) == 100)
        #expect(collapse.restingOffset(for: 0) == 0)
        #expect(collapse.restingOffset(for: -20) == -20)
        #expect(collapse.restingOffset(for: 100) == 100)
        #expect(collapse.restingOffset(for: 340) == 340)
    }

    @Test
    func `between two pages, the fold is blended, not the offsets`() {
        #expect(collapse.progress(of: [2_000, 0], pagePosition: 0) == 1)
        #expect(collapse.progress(of: [2_000, 0], pagePosition: 0.5) == 0.5)
        #expect(collapse.progress(of: [2_000, 0], pagePosition: 1) == 0)
        #expect(collapse.progress(of: [50, 100], pagePosition: 0.5) == 0.75)
        #expect(collapse.progress(of: [2_000, 0], pagePosition: -0.2) == 1)
        #expect(collapse.progress(of: [2_000, 0], pagePosition: 1.3) == 0)
    }

    @Test
    func `across three pages, only the two the pager stands between count`() {
        let offsets: [CGFloat] = [0, 2_000, 50]
        #expect(collapse.progress(of: offsets, pagePosition: 0) == 0)
        #expect(collapse.progress(of: offsets, pagePosition: 1) == 1)
        #expect(collapse.progress(of: offsets, pagePosition: 1.5) == 0.75)
        #expect(collapse.progress(of: offsets, pagePosition: 2) == 0.5)
        #expect(collapse.progress(of: offsets, pagePosition: 2.4) == 0.5)
        #expect(collapse.progress(of: [], pagePosition: 1) == 0)
    }

    @Test
    func `any value per page blends the same way`() {
        #expect(FoldingHeaderCollapse.blend([0, 40, 10], at: 0.5) == 20)
        #expect(FoldingHeaderCollapse.blend([0, 40, 10], at: 1.5) == 25)
        #expect(FoldingHeaderCollapse.blend([7], at: 3) == 7)
    }

    @Test
    func `values move from their resting size to their folded one`() {
        #expect(FoldingHeaderCollapse.interpolate(from: 96, to: 40, progress: 0) == 96)
        #expect(FoldingHeaderCollapse.interpolate(from: 96, to: 40, progress: 0.5) == 68)
        #expect(FoldingHeaderCollapse.interpolate(from: 96, to: 40, progress: 1) == 40)
    }
}
