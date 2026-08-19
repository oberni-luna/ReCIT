//
//  ShelfLabelTiltTests.swift
//  ReCIT_iOSTests
//
//  Unit tests for the shelf label's lean. Pure and network-free, like the layout suite.
//
//  Two of these exist to pin failures that are invisible by eye. A process-seeded hash
//  looks perfect within any single run and re-rolls every launch, so stability is asserted
//  rather than observed; and an ASCII fold drops accented characters, so a shelf of French
//  names would quietly share one angle. See PRD 0003.
//

import Testing
@testable import ReCIT_iOS

@Suite struct ShelfLabelTiltTests {

    /// Names of the shape a French collector actually types, plus the awkward edges.
    private let names: [String] = [
        "Classiques français",
        "Littérature étrangère",
        "Bandes dessinées",
        "Éditions rares",
        "Romans policiers",
        "Poésie",
        "Science-fiction",
        "Essais et documents",
        "Livres d'enfance",
        "Théâtre",
        "Philosophie",
        "Beaux-arts"
    ]

    // MARK: - Range

    @Test func everyAngleStaysWithinADegree() {
        for name in names {
            let angle: Double = ShelfLabelTilt.degrees(for: name)
            #expect(angle >= -ShelfLabelTilt.maximumDegrees)
            #expect(angle <= ShelfLabelTilt.maximumDegrees)
        }
    }

    @Test func edgeCaseTextsStayWithinRange() {
        for text in ["", " ", "A", String(repeating: "é", count: 500), "📚 Manga", "0"] {
            let angle: Double = ShelfLabelTilt.degrees(for: text)
            #expect(angle >= -ShelfLabelTilt.maximumDegrees)
            #expect(angle <= ShelfLabelTilt.maximumDegrees)
        }
    }

    // MARK: - Stability

    @Test func theSameTextAlwaysLeansTheSameWay() {
        for name in names {
            let first: Double = ShelfLabelTilt.degrees(for: name)
            for _ in 0..<50 {
                #expect(ShelfLabelTilt.degrees(for: name) == first)
            }
        }
    }

    @Test func anEqualStringBuiltAnotherWayLeansTheSameWay() {
        // Same text, different provenance — nothing about the angle may depend on identity.
        let built: String = "Classiques" + " " + "français"
        #expect(ShelfLabelTilt.degrees(for: built) == ShelfLabelTilt.degrees(for: "Classiques français"))
    }

    // MARK: - Accents

    @Test func accentedNamesDoNotCollapseOntoOneAngle() {
        let accented: [String] = [
            "Classiques français",
            "Littérature étrangère",
            "Bandes dessinées",
            "Éditions rares"
        ]
        let angles: Set<Double> = .init(accented.map(ShelfLabelTilt.degrees(for:)))
        #expect(angles.count == accented.count)
    }

    @Test func anAccentChangesTheAngle() {
        // The one assertion an ASCII-byte fold cannot pass: these differ only in their
        // accents, so ignoring them would give both names the same lean.
        let pairs: [(String, String)] = [
            ("Éditions rares", "Editions rares"),
            ("Classiques français", "Classiques francais"),
            ("Littérature étrangère", "Litterature etrangere"),
            ("Bandes dessinées", "Bandes dessinees")
        ]
        for (accented, plain) in pairs {
            #expect(ShelfLabelTilt.degrees(for: accented) != ShelfLabelTilt.degrees(for: plain))
        }
    }

    // MARK: - Spread

    @Test func realisticNamesSpreadAcrossTheRangeRatherThanClustering() {
        // Quarters of -1...1: every one of them has to be used, or the shelves all lean
        // the same way despite each angle being technically distinct.
        var occupied: Set<Int> = []
        for name in names {
            let angle: Double = ShelfLabelTilt.degrees(for: name)
            let quarter: Int = min(3, Int((angle + ShelfLabelTilt.maximumDegrees) / (ShelfLabelTilt.maximumDegrees / 2)))
            occupied.insert(quarter)
        }
        #expect(occupied.count == 4)
    }

    @Test func realisticNamesAllGetTheirOwnAngle() {
        let angles: Set<Double> = .init(names.map(ShelfLabelTilt.degrees(for:)))
        #expect(angles.count == names.count)
    }

    @Test func leansGoBothWays() {
        #expect(names.contains { ShelfLabelTilt.degrees(for: $0) < 0 })
        #expect(names.contains { ShelfLabelTilt.degrees(for: $0) > 0 })
    }
}
