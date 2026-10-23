//
//  AvatarMetricsTests.swift
//  ReCIT_iOSTests
//
//  The shared avatar's fallback (PRD 0019, Q21, Q21 bis, Q37): a reader is a disc, a group never
//  is; the initials take `action300` from 44 pt and `action200` below; the glyph is 24 pt at 44
//  and 18 pt at 32; under 32 pt there is no mark.
//

import CoreGraphics
import Testing
@testable import ReCIT_iOS

@Suite("Avatar fallback")
struct AvatarMetricsTests {

    @Test("A reader is round and a group never is")
    func shape() {
        #expect(AvatarKind.reader(username: "Léa").isRound)
        #expect(AvatarKind.group.isRound == false)
    }

    @Test("A reader is drawn with their initials, a group with none")
    func initials() {
        #expect(AvatarKind.reader(username: "olivier_berni").initials == "OB")
        #expect(AvatarKind.group.initials == nil)
    }

    @Test(
        "Large type from 44 pt, small type below",
        arguments: [
            (CGFloat(72), true),
            (64, true),
            (48, true),
            (44, true),
            (43.5, false),
            (36, false),
            (32, false)
        ]
    )
    func typeSize(side: CGFloat, usesLargeType: Bool) {
        #expect(AvatarMetrics(side: side).usesLargeType == usesLargeType)
    }

    @Test("The glyph is the size Figma draws at 44 and 32, and keeps that proportion")
    func glyphSide() {
        #expect(AvatarMetrics(side: 44).glyphSide == 24)
        #expect(AvatarMetrics(side: 32).glyphSide == 18)
        #expect(AvatarMetrics(side: 48).glyphSide == 26)
        #expect(AvatarMetrics(side: 64).glyphSide == 35)
        #expect(AvatarMetrics(side: 36).glyphSide == 20)
    }

    @Test("A 24 pt dot shows the tinted fill alone")
    func noMarkUnder32() {
        #expect(AvatarMetrics(side: 24).showsMark == false)
        #expect(AvatarMetrics(side: 32).showsMark)
        #expect(AvatarMetrics(side: 48).showsMark)
    }
}
