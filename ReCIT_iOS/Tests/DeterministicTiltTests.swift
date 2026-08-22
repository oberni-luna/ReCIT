//
//  DeterministicTiltTests.swift
//  ReCIT_iOSTests
//
//  The angle machinery both the paper labels (±1°) and the sorting surface's piled covers
//  (±10°) lean on. `ShelfLabelTiltTests` pins the label's own amplitude; this suite pins the
//  two failures that are invisible by eye at *any* amplitude — a process-seeded hash, which
//  looks perfect within one run and re-rolls on the next, and an ASCII fold, which would
//  give a shelf of accented French names one shared angle. See PRD 0003 and PRD 0009.
//

import Testing
@testable import ReCIT_iOS

@Suite("DeterministicTilt")
struct DeterministicTiltTests {

    private let texts: [String] = [
        "Classiques français",
        "Littérature étrangère",
        "Le ministère des rêves",
        "Étincelles écosocialistes",
        "Le chaos qui vient",
        "Théâtre",
        "Poésie"
    ]

    @Test(arguments: [1.0, 10.0]) func everyAngleStaysWithinItsAmplitude(amplitude: Double) {
        for text in texts + ["", " ", "A", "📚", String(repeating: "é", count: 500)] {
            let angle: Double = DeterministicTilt.degrees(for: text, amplitude: amplitude)

            #expect(angle >= -amplitude)
            #expect(angle <= amplitude)
        }
    }

    /// Stability is asserted rather than observed: `String.hashValue` is seeded per process,
    /// so a pile derived from it would lean differently on every cold start — a bug no
    /// single run can see.
    @Test func theSameTextAlwaysLeansTheSameWay() {
        for text in texts {
            let first: Double = DeterministicTilt.degrees(for: text, amplitude: 10)
            let second: Double = DeterministicTilt.degrees(for: text, amplitude: 10)

            #expect(first == second)
        }
    }

    /// The hard-coded values pin the fold itself: change the hash and this test fails, which
    /// is the point — a silent change would re-roll every pile in the app.
    @Test func theFoldIsPinnedAcrossLaunches() {
        #expect(abs(DeterministicTilt.degrees(for: "Science-fiction", amplitude: 10) - -2.90) < 0.01)
        #expect(abs(DeterministicTilt.degrees(for: "Poésie", amplitude: 10) - 3.69) < 0.01)
    }

    /// An ASCII fold would drop the accents and hand these two the same angle.
    @Test func accentsChangeTheAngle() {
        let accented: Double = DeterministicTilt.degrees(for: "Poésie", amplitude: 10)
        let plain: Double = DeterministicTilt.degrees(for: "Poesie", amplitude: 10)

        #expect(accented != plain)
    }

    /// Amplitude scales the same angle rather than picking a different one, so a label and a
    /// cover carrying the same text lean the same way, to different degrees.
    @Test func amplitudeScalesTheSameLean() {
        for text in texts {
            let small: Double = DeterministicTilt.degrees(for: text, amplitude: 1)
            let large: Double = DeterministicTilt.degrees(for: text, amplitude: 10)

            #expect(abs(large - small * 10) < 0.0001)
        }
    }

    @Test func neighbouringTextsDoNotShareAnAngle() {
        let angles: [Double] = ["Livre 1", "Livre 2", "Livre 3", "Livre 4"]
            .map { DeterministicTilt.degrees(for: $0, amplitude: 10) }

        #expect(Set(angles).count == 4)
    }
}
