//
//  ShelfBookPullTests.swift
//  ReCIT_iOSTests
//
//  Created by Olivier Berni on 20/11/2026.
//

import CoreGraphics
import Testing
@testable import ReCIT_iOS

@Suite
struct ShelfBookPullTests {
    private let spine: ShelfBookPull = .init(
        bookSize: .init(width: 25, height: 150),
        growth: 2
    )
    private let cover: ShelfBookPull = .init(
        bookSize: .init(width: 100, height: 150),
        growth: 2
    )
    private let gaps: [CGFloat] = [0, 1, 5, 10, 20, 50, 100, 1_000, 100_000]

    @Test
    func `does not move while the finger is on the book's centre`() {
        #expect(cover.offset(towards: .zero) == .zero)
    }

    @Test
    func `leans the way the finger is`() {
        let pull: CGSize = cover.offset(towards: .init(width: -30, height: 40))

        #expect(pull.width < 0)
        #expect(pull.height > 0)
    }

    @Test
    func `leans as far either way`() {
        for gap in gaps {
            let right: CGSize = cover.offset(towards: .init(width: gap, height: gap))
            let left: CGSize = cover.offset(towards: .init(width: -gap, height: -gap))

            #expect(left.width == -right.width)
            #expect(left.height == -right.height)
        }
    }

    @Test
    func `leans further the further the finger goes`() {
        let pulls: [CGFloat] = gaps.map { cover.offset(towards: .init(width: $0, height: 0)).width }

        for (nearer, further) in zip(pulls, pulls.dropFirst()) {
            #expect(nearer < further)
        }
    }

    @Test
    func `never goes past the cap`() {
        for gap in gaps {
            let pull: CGSize = spine.offset(towards: .init(width: gap, height: -gap))

            #expect(abs(pull.width) < spine.cap.width)
            #expect(abs(pull.height) < spine.cap.height)
        }
    }

    @Test
    func `caps a large book at twenty points`() {
        #expect(cover.cap == .init(width: 20, height: 20))
    }

    @Test
    func `caps a thin spine at half its extra growth`() {
        #expect(spine.cap == .init(width: 12.5, height: 20))
    }

    @Test
    func `pulls each axis on its own`() {
        let sideways: CGSize = spine.offset(towards: .init(width: 100, height: 0))
        let diagonal: CGSize = spine.offset(towards: .init(width: 100, height: 500))

        #expect(sideways.height == 0)
        #expect(sideways.width == diagonal.width)
    }

    @Test
    func `does not move a book that has not grown`() {
        let resting: ShelfBookPull = .init(
            bookSize: .init(width: 100, height: 150),
            growth: 1
        )

        #expect(resting.cap == .zero)
        #expect(resting.offset(towards: .init(width: 50, height: -50)) == .zero)
    }
}
