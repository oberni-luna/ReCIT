//
//  MeCentredStackTests.swift
//  ReCIT_iOSTests
//
//  The empty state of « Tout » puts « Vous » at the centre of the room, where the graph will put
//  it, and the sentence and the first steps under it; with less room « Vous » climbs just enough
//  to keep the last part on screen, never above the top (E1, PRD 0019, Q39).
//

import CoreGraphics
import Testing
@testable import ReCIT_iOS

@Suite("MeCentredStack")
struct MeCentredStackTests {

    /// « Vous » 84 tall, a sentence 44, the two links 98, 24 apart — E1 at the default size.
    private let stack: MeCentredStack = .init(heights: [84, 44, 98], spacing: 24)

    @Test("The parts stacked tight")
    func compactHeight() {
        #expect(stack.compactHeight == 274)
        #expect(MeCentredStack(heights: [84], spacing: 24).compactHeight == 84)
        #expect(MeCentredStack(heights: [], spacing: 24).compactHeight == 0)
    }

    @Test("With room enough, « Vous » is centred and the rest follows it")
    func centred() {
        let tops: [CGFloat] = stack.tops(in: 682)
        let expected: [CGFloat] = [299, 407, 475]

        #expect(tops == expected)
        #expect(tops[0] + 42 == 341)
    }

    /// E1 in Figma: the avatar's centre, 36 down from the top of « Vous », is the centre of the
    /// 682 pt graph area, and the block starts at 305.
    @Test("Centred on its avatar, « Vous » sits where the graph will put it")
    func centredOnTheAvatar() {
        let anchored: MeCentredStack = .init(heights: [84, 44, 98], spacing: 24, leadAnchor: 36)
        let tops: [CGFloat] = anchored.tops(in: 682)
        let expected: [CGFloat] = [305, 413, 481]

        #expect(tops == expected)
        #expect(tops[0] + 36 == 341)
    }

    @Test("Short of room, « Vous » climbs until the last part ends at the bottom")
    func climbs() {
        let height: CGFloat = 400
        let tops: [CGFloat] = stack.tops(in: height)

        #expect(tops[0] < (height - 84) / 2)
        #expect(tops[2] + 98 == height)
    }

    @Test("Shorter than the parts, « Vous » stays at the top")
    func neverAboveTheTop() {
        #expect(stack.tops(in: 200).first == 0)
    }

    @Test("No part, no position")
    func empty() {
        #expect(MeCentredStack(heights: [], spacing: 24).tops(in: 682).isEmpty)
    }
}
