//
//  LensTabTrackTests.swift
//  ReCIT_iOSTests
//

import CoreGraphics
import Testing
@testable import ReCIT_iOS

@Suite("LensTabTrack")
struct LensTabTrackTests {
    /// Three words: 0–100, 100–160, 160–260 — centres at 50, 130 and 210.
    private let track: LensTabTrack = .init(frames: [
        .init(x: 0, y: 0, width: 100, height: 30),
        .init(x: 100, y: 0, width: 60, height: 30),
        .init(x: 160, y: 0, width: 100, height: 30),
    ])

    @Test("The capsule goes from one word's frame to the next, and stays on the ends past them")
    func capsuleFrame() {
        #expect(track.capsuleFrame(at: 0) == .init(x: 0, y: 0, width: 100, height: 30))
        #expect(track.capsuleFrame(at: 0.5) == .init(x: 50, y: 0, width: 80, height: 30))
        #expect(track.capsuleFrame(at: 2) == .init(x: 160, y: 0, width: 100, height: 30))
        #expect(track.capsuleFrame(at: 3.4) == track.capsuleFrame(at: 2))
        #expect(track.capsuleFrame(at: -1) == track.capsuleFrame(at: 0))
        #expect(LensTabTrack(frames: []).capsuleFrame(at: 0) == nil)
    }

    @Test("A finger's x reads back into the position that puts the capsule's centre under it")
    func positionForCenter() {
        #expect(track.position(forCenter: 50) == 0)
        #expect(track.position(forCenter: 90) == 0.5)
        #expect(track.position(forCenter: 130) == 1)
        #expect(track.position(forCenter: 170) == 1.5)
        #expect(track.position(forCenter: -20) == 0)
        #expect(track.position(forCenter: 400) == 2)
        #expect(LensTabTrack(frames: []).position(forCenter: 10) == nil)

        for position in [0.25, 0.8, 1.3, 1.9] as [CGFloat] {
            let center: CGFloat = track.capsuleFrame(at: position)?.midX ?? 0
            #expect(abs((track.position(forCenter: center) ?? -1) - position) < 0.0001)
        }
    }

    @Test("Past the ends the capsule follows less and less, and never past the limit")
    func overshoot() {
        #expect(track.overshoot(forCenter: 130) == 0)
        #expect(track.overshoot(forCenter: 50) == 0)

        let near: CGFloat = track.overshoot(forCenter: 220)
        let far: CGFloat = track.overshoot(forCenter: 310)
        let farther: CGFloat = track.overshoot(forCenter: 2_000)
        #expect(near > 0 && near < 10)
        #expect(far > near && far < 100)
        #expect(farther > far && farther < LensTabTrack.overshootLimit)
        #expect(track.overshoot(forCenter: 50 - 100) == -far)
    }

    @Test("Pulled past the end, the far edge follows the finger and the near one half as much")
    func lensStretch() {
        let resting: CGRect? = track.lensFrame(at: 2, scale: 1, overshoot: 0)
        #expect(resting == track.capsuleFrame(at: 2))

        let pulled: CGRect = track.lensFrame(at: 2, scale: 1, overshoot: 20) ?? .zero
        #expect(isClose(pulled.maxX, 260 + 20))
        #expect(isClose(pulled.minX, 160 + 10))
        #expect(pulled.height < 30)

        let pushed: CGRect = track.lensFrame(at: 0, scale: 1, overshoot: -20) ?? .zero
        #expect(isClose(pushed.minX, -20))
        #expect(isClose(pushed.maxX, 100 - 10))
    }

    private func isClose(_ value: CGFloat, _ expected: CGFloat) -> Bool {
        abs(value - expected) < 0.0001
    }

    @Test("Lifted, the capsule grows about its centre")
    func lift() {
        let lifted: CGRect = track.lensFrame(at: 1, scale: 1.5, overshoot: 0) ?? .zero
        #expect(lifted.midX == 130)
        #expect(lifted.midY == 15)
        #expect(lifted.width == 90)
        #expect(lifted.height == 45)
    }

    @Test("Let go still, the capsule settles on the nearest word")
    func releaseStill() {
        #expect(track.releaseIndex(position: 0.4, center: 82, velocity: 0) == 0)
        #expect(track.releaseIndex(position: 0.6, center: 98, velocity: 0) == 1)
        #expect(track.releaseIndex(position: 2, center: 210, velocity: 0) == 2)
    }

    @Test("Flung, it goes one word further at most, and never past the last")
    func releaseFlung() {
        // From the first word, a flick that would carry it to the last stops on the second.
        #expect(track.releaseIndex(position: 0.2, center: 66, velocity: 3_000) == 1)
        #expect(track.releaseIndex(position: 0.2, center: 66, velocity: 200) == 0)
        #expect(track.releaseIndex(position: 1.8, center: 194, velocity: -3_000) == 1)
        #expect(track.releaseIndex(position: 2, center: 210, velocity: 3_000) == 2)
    }
}
