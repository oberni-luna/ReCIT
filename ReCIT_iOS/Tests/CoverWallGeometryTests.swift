//
//  CoverWallGeometryTests.swift
//  ReCIT_iOSTests
//
//  The two invariants of the wall, which no screenshot can prove: it **tiles** its container at
//  every instant, and it **loops** without a jump. A screenshot taken at the wrong second shows
//  a wall that looks fine and tears two seconds later — so both are asserted arithmetically,
//  at the four widths the app runs at and at a spread of instants.
//
//  See PRD 0011.
//

import Testing
import CoreGraphics
import Foundation
@testable import ReCIT_iOS

@Suite("CoverWallGeometry")
struct CoverWallGeometryTests {

    /// iPhone SE, iPhone 13 mini / SE 3, iPhone 17, iPhone 17 Pro Max.
    private let sizes: [CGSize] = [
        .init(width: 320, height: 568),
        .init(width: 375, height: 667),
        .init(width: 393, height: 852),
        .init(width: 430, height: 932),
    ]

    /// A spread of instants, including a fraction of a second and a long stay on the screen.
    private let instants: [TimeInterval] = [0, 0.4, 3.7, 42, 617.25]

    // MARK: - Measurements

    @Test func theColumnsFillTheWidthExactly() {
        for size in sizes {
            let geometry: CoverWallGeometry = .init(size: size)
            let laidOut: CGFloat = geometry.coverWidth * 4 + CoverWallGeometry.gutter * 5

            #expect(abs(laidOut - size.width) < 0.01)
        }
    }

    @Test func aCoverKeepsItsTwoThirdsShape() {
        for size in sizes {
            let geometry: CoverWallGeometry = .init(size: size)

            #expect(abs(geometry.coverWidth / geometry.coverHeight - 2.0 / 3.0) < 0.001)
        }
    }

    /// The wrapped band spans one row above the container and the rest of the period below, so
    /// the period has to be taller than the container by at least that row.
    @Test func thePeriodIsTallerThanTheContainer() {
        for size in sizes {
            let geometry: CoverWallGeometry = .init(size: size)

            #expect(geometry.period >= size.height + geometry.rowPitch)
        }
    }

    // MARK: - Tiling

    /// The invariant that matters: at any instant, a column runs from above the top edge to
    /// below the bottom one, its covers one pitch apart the whole way. The wall shows the
    /// ground between two covers — that gap is the gutter, and it is drawn on purpose — but it
    /// must never grow: a column that starts below the top edge, ends above the bottom one, or
    /// skips a row, has a hole in it.
    @Test func everyColumnSpansTheScreenAtEveryInstant() {
        for size in sizes {
            let geometry: CoverWallGeometry = .init(size: size)

            for instant in instants {
                for column in 0..<geometry.columnCount {
                    let tops: [CGFloat] = (0..<geometry.rowCount)
                        .map { row in
                            geometry.y(
                                ofRow: row,
                                inColumn: column,
                                at: instant,
                                speedScale: 1
                            )
                        }
                        .sorted()

                    #expect(
                        tops[0] <= 0,
                        "column \(column) starts below the top edge at \(instant)s"
                    )
                    #expect(
                        tops[tops.count - 1] + geometry.coverHeight >= size.height,
                        "column \(column) stops above the bottom edge at \(instant)s"
                    )

                    for (index, top) in tops.enumerated().dropFirst() {
                        #expect(
                            abs(top - tops[index - 1] - geometry.rowPitch) < 0.01,
                            "column \(column) skips a row at \(instant)s"
                        )
                    }
                }
            }
        }
    }

    // MARK: - The loop

    /// A column is back exactly where it started after one period, so the loop has no seam.
    @Test func aColumnIsBackWhereItStartedAfterOnePeriod() {
        let geometry: CoverWallGeometry = .init(size: .init(width: 393, height: 852))

        for column in 0..<geometry.columnCount {
            let period: TimeInterval = .init(geometry.period / geometry.speed(ofColumn: column))
            let start: CGFloat = geometry.y(ofRow: 0, inColumn: column, at: 0, speedScale: 1)
            let afterOneLoop: CGFloat = geometry.y(
                ofRow: 0,
                inColumn: column,
                at: period,
                speedScale: 1
            )

            #expect(abs(afterOneLoop - start) < 0.01)
        }
    }

    /// Between two close instants a cover moves by speed × elapsed, and never by a jump —
    /// measured around the period, so a wrap counts as continuous rather than as a leap.
    @Test func aCoverMovesAtItsColumnSpeedWithoutJumping() {
        let geometry: CoverWallGeometry = .init(size: .init(width: 393, height: 852))
        let step: TimeInterval = 0.05

        for column in 0..<geometry.columnCount {
            let expected: CGFloat = geometry.speed(ofColumn: column) * CGFloat(step)

            for instant in instants {
                let before: CGFloat = geometry.y(
                    ofRow: 3,
                    inColumn: column,
                    at: instant,
                    speedScale: 1
                )
                let after: CGFloat = geometry.y(
                    ofRow: 3,
                    inColumn: column,
                    at: instant + step,
                    speedScale: 1
                )
                // Measured along the column's own direction, so an upward column reads as
                // travelling forward rather than as travelling a whole period backwards.
                let travelled: CGFloat = geometry.direction(ofColumn: column) == 1
                    ? circularDistance(from: before, to: after, period: geometry.period)
                    : circularDistance(from: after, to: before, period: geometry.period)

                #expect(abs(travelled - expected) < 0.01)
            }
        }
    }

    @Test func theColumnsTravelInAlternatingDirections() {
        let geometry: CoverWallGeometry = .init(size: .init(width: 393, height: 852))

        #expect(geometry.direction(ofColumn: 0) == 1)
        #expect(geometry.direction(ofColumn: 1) == -1)
        #expect(geometry.direction(ofColumn: 2) == 1)
        #expect(geometry.direction(ofColumn: 3) == -1)
    }

    /// No two columns start in step: aligned phases open the screen on a perfect checkerboard.
    @Test func noTwoColumnsStartInStep() {
        let geometry: CoverWallGeometry = .init(size: .init(width: 393, height: 852))
        let phases: [CGFloat] = (0..<geometry.columnCount).map { geometry.phase(ofColumn: $0) }

        for (index, phase) in phases.enumerated() {
            for other in phases.dropFirst(index + 1) {
                #expect(abs(phase - other) > 1)
            }
        }
    }

    /// Frozen, the wall is still a wall: a zero pace leaves every cover on its phase, and the
    /// screen is identical at every instant.
    @Test func aFrozenWallDoesNotMove() {
        let geometry: CoverWallGeometry = .init(size: .init(width: 393, height: 852))

        for column in 0..<geometry.columnCount {
            let atZero: CGFloat = geometry.y(ofRow: 2, inColumn: column, at: 0, speedScale: 0)
            let muchLater: CGFloat = geometry.y(
                ofRow: 2,
                inColumn: column,
                at: 3_600,
                speedScale: 0
            )

            #expect(atZero == muchLater)
        }
    }

    // MARK: - What goes in a slot

    @Test func withoutImagesEverySlotIsPainted() {
        let geometry: CoverWallGeometry = .init(size: .init(width: 393, height: 852))

        for column in 0..<geometry.columnCount {
            for row in 0..<geometry.rowCount {
                #expect(geometry.imageIndex(ofRow: row, inColumn: column, imageCount: 0) == nil)
            }
        }
    }

    @Test func aSingleImageFillsEverySlot() {
        let geometry: CoverWallGeometry = .init(size: .init(width: 393, height: 852))

        for column in 0..<geometry.columnCount {
            for row in 0..<geometry.rowCount {
                #expect(geometry.imageIndex(ofRow: row, inColumn: column, imageCount: 1) == 0)
            }
        }
    }

    /// Sixty covers on a grid of about thirty-two slots: nothing is drawn twice, so no cover
    /// sits next to itself.
    @Test func afullFeedNeverRepeatsACover() {
        let geometry: CoverWallGeometry = .init(size: .init(width: 393, height: 852))
        var seen: Set<Int> = []
        var slots: Int = 0

        for column in 0..<geometry.columnCount {
            for row in 0..<geometry.rowCount {
                slots += 1
                if let index = geometry.imageIndex(
                    ofRow: row,
                    inColumn: column,
                    imageCount: 60
                ) {
                    seen.insert(index)
                }
            }
        }

        #expect(slots <= 60, "the grid outgrew the feed this test assumes")
        #expect(seen.count == slots)
    }

    /// Fewer images than slots: the fill cycles rather than leaving holes, and no slot is empty.
    @Test func aShortFeedCyclesRatherThanLeavingHoles() {
        let geometry: CoverWallGeometry = .init(size: .init(width: 393, height: 852))

        for column in 0..<geometry.columnCount {
            for row in 0..<geometry.rowCount {
                let index: Int? = geometry.imageIndex(
                    ofRow: row,
                    inColumn: column,
                    imageCount: 5
                )

                #expect(index != nil)
                #expect(index.map { (0..<5).contains($0) } == true)
            }
        }
    }

    @Test func theSamePaintedWallIsDrawnTwice() {
        let first: CoverWallGeometry = .init(size: .init(width: 393, height: 852))
        let second: CoverWallGeometry = .init(size: .init(width: 393, height: 852))

        for column in 0..<first.columnCount {
            for row in 0..<first.rowCount {
                #expect(
                    first.paintedIndex(ofRow: row, inColumn: column, variantCount: 6)
                        == second.paintedIndex(ofRow: row, inColumn: column, variantCount: 6)
                )
            }
        }
    }

    // MARK: - Degenerate containers

    /// A wall asked for no space draws nothing, and answers questions without dividing by zero.
    @Test func anEmptyContainerDrawsNothing() {
        let geometry: CoverWallGeometry = .init(size: .zero)

        #expect(geometry.rowCount == 0)
        #expect(geometry.y(ofRow: 0, inColumn: 0, at: 12, speedScale: 1) == 0)
    }

    @Test func oneColumnIsStillAWall() {
        let geometry: CoverWallGeometry = .init(
            size: .init(width: 393, height: 852),
            columnCount: 1
        )

        #expect(geometry.columnCount == 1)
        #expect(geometry.rowCount > 0)
        #expect(abs(geometry.coverWidth * 1 + CoverWallGeometry.gutter * 2 - 393) < 0.01)
    }

    // MARK: - Helpers

    /// How far a point travelled downward between two positions on a loop of `period`.
    private func circularDistance(from: CGFloat, to: CGFloat, period: CGFloat) -> CGFloat {
        let raw: CGFloat = (to - from).truncatingRemainder(dividingBy: period)
        return raw < 0 ? raw + period : raw
    }
}
