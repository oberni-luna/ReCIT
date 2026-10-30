//
//  ProfileHeaderCollapseTests.swift
//  ReCIT_iOSTests
//

import CoreGraphics
import Testing
@testable import ReCIT_iOS

@Suite("ProfileHeaderCollapse")
struct ProfileHeaderCollapseTests {
    private let collapse: ProfileHeaderCollapse = .init(distance: 100)

    @Test("The fold follows the scroll, and stops at both ends")
    func progress() {
        #expect(collapse.progress(at: -40) == 0)
        #expect(collapse.progress(at: 0) == 0)
        #expect(collapse.progress(at: 25) == 0.25)
        #expect(collapse.progress(at: 100) == 1)
        #expect(collapse.progress(at: 600) == 1)
        #expect(ProfileHeaderCollapse(distance: 0).progress(at: 50) == 0)
    }

    @Test("The page passes under the header only once it is folded")
    func contentUnder() {
        #expect(collapse.isContentUnder(at: 100) == false)
        #expect(collapse.isContentUnder(at: 101))
    }

    @Test("A scroll left inside the fold lands on the nearer side; elsewhere it stays")
    func restingOffset() {
        #expect(collapse.restingOffset(for: 30) == 0)
        #expect(collapse.restingOffset(for: 50) == 100)
        #expect(collapse.restingOffset(for: 80) == 100)
        #expect(collapse.restingOffset(for: 0) == 0)
        #expect(collapse.restingOffset(for: -20) == -20)
        #expect(collapse.restingOffset(for: 100) == 100)
        #expect(collapse.restingOffset(for: 340) == 340)
    }

    @Test("Values move from their resting size to their folded one")
    func interpolate() {
        #expect(ProfileHeaderCollapse.interpolate(from: 96, to: 40, progress: 0) == 96)
        #expect(ProfileHeaderCollapse.interpolate(from: 96, to: 40, progress: 0.5) == 68)
        #expect(ProfileHeaderCollapse.interpolate(from: 96, to: 40, progress: 1) == 40)
    }
}
