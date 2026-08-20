//
//  AutoSortEntryPointTests.swift
//  ReCIT_iOSTests
//
//  The one part of availability handling that is logic rather than platform state:
//  which of the three unavailability reasons gets hidden, which gets explained, and
//  which gets waited out. Pure and network-free, like the rest of the auto-sort suites.
//
//  Worth pinning because the failure is invisible in the simulator, where Apple
//  Intelligence is simply available: collapsing the three reasons back into one
//  blanket wall would compile, look right on every device a developer owns, and nag a
//  user about a chip they cannot change. The empty card's fallback is here for the
//  same reason — it is the one entry point that cannot be hidden, so a reason that
//  wrongly stopped it reaching the flow would turn the app's whole invitation to tidy
//  a library into a form. See PRD 0006.
//

import Testing
@testable import ReCIT_iOS

@Suite("AutoSortEntryPoint")
struct AutoSortEntryPointTests {

    // MARK: - Mapping

    @Test func offersTheFeatureWhenTheModelIsAvailable() {
        let entryPoint: AutoSortEntryPoint = .init(availability: .available)

        #expect(entryPoint == .offered)
        #expect(entryPoint.isVisible)
        #expect(entryPoint.isEnabled)
        #expect(entryPoint.offersSettingsRoute == false)
    }

    /// Nothing the user can do about the chip in their phone, so they are told nothing.
    @Test func hidesEverythingOnAnIneligibleDevice() {
        let entryPoint: AutoSortEntryPoint = .init(availability: .deviceNotEligible)

        #expect(entryPoint == .hidden)
        #expect(entryPoint.isVisible == false)
        #expect(entryPoint.isEnabled == false)
        #expect(entryPoint.offersSettingsRoute == false)
    }

    /// Actionable, so it is stated and routed — the only reason that earns a Settings button.
    @Test func explainsAndRoutesToSettingsWhenAppleIntelligenceIsOff() {
        let entryPoint: AutoSortEntryPoint = .init(availability: .appleIntelligenceNotEnabled)

        #expect(entryPoint == .switchedOff)
        #expect(entryPoint.isVisible)
        #expect(entryPoint.isEnabled == false)
        #expect(entryPoint.offersSettingsRoute)
    }

    /// Transient, so it is shown inert rather than hidden — and without a Settings button,
    /// which would send the user to a switch that is already flipped.
    @Test func showsItInertWhileTheModelDownloads() {
        let entryPoint: AutoSortEntryPoint = .init(availability: .modelNotReady)

        #expect(entryPoint == .downloading)
        #expect(entryPoint.isVisible)
        #expect(entryPoint.isEnabled == false)
        #expect(entryPoint.offersSettingsRoute == false)
    }

    // MARK: - Each reason gets its own treatment

    @Test func distinguishesTheThreeUnavailableReasons() {
        let reasons: [AutoSortEntryPoint] = [
            .init(availability: .deviceNotEligible),
            .init(availability: .appleIntelligenceNotEnabled),
            .init(availability: .modelNotReady)
        ]

        #expect(reasons[0] != reasons[1])
        #expect(reasons[1] != reasons[2])
        #expect(reasons[0] != reasons[2])
        #expect(reasons.allSatisfy { $0.isEnabled == false })
    }
}
