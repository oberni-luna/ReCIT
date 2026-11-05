//
//  ListArrivalFocusTests.swift
//  ReCIT_iOSTests
//
//  Created by Olivier Berni on 05/11/2026.
//

import Testing
@testable import ReCIT_iOS

@Suite
struct ListArrivalFocusTests {
    @Test
    func `scrolls from the first element to the focused one, then rings it once centred`() {
        var arrival: ListArrivalFocus = .init(focusURI: "wd:Q2")

        let move: ListArrivalFocus.Move? = arrival.start(in: ["wd:Q1", "wd:Q2"], selectedURI: nil, reduceMotion: false)
        #expect(move == .scroll("wd:Q2"))
        #expect(arrival.highlightedURI == nil)

        arrival.land(on: "wd:Q2")
        #expect(arrival.highlightedURI == "wd:Q2")

        arrival.endHighlight()
        #expect(arrival.phase == .done)
    }

    @Test
    func `does nothing for a list opened without a focus`() {
        var arrival: ListArrivalFocus = .init(focusURI: nil)

        let move: ListArrivalFocus.Move? = arrival.start(in: ["wd:Q1", "wd:Q2"], selectedURI: nil, reduceMotion: false)
        arrival.land(on: "wd:Q1")

        #expect(move == nil)
        #expect(arrival.phase == .done)
        #expect(arrival.highlightedURI == nil)
    }

    @Test
    func `jumps straight to the focused element under Reduce Motion`() {
        var arrival: ListArrivalFocus = .init(focusURI: "wd:Q2")

        let move: ListArrivalFocus.Move? = arrival.start(in: ["wd:Q1", "wd:Q2"], selectedURI: nil, reduceMotion: true)

        #expect(move == .jump("wd:Q2"))
        #expect(arrival.phase == .arriving(.jump("wd:Q2")))
    }

    @Test
    func `puts the halo out when the reader picks another element`() {
        var arrival: ListArrivalFocus = .init(focusURI: "wd:Q2")
        arrival.start(in: ["wd:Q1", "wd:Q2"], selectedURI: "wd:Q1", reduceMotion: false)
        arrival.land(on: "wd:Q2")

        arrival.select("wd:Q2")
        #expect(arrival.highlightedURI == "wd:Q2")

        arrival.select("wd:Q1")
        #expect(arrival.phase == .done)
    }

    @Test
    func `rings nothing when the reader moved away during the scroll`() {
        var arrival: ListArrivalFocus = .init(focusURI: "wd:Q2")
        arrival.start(in: ["wd:Q1", "wd:Q2"], selectedURI: "wd:Q1", reduceMotion: false)

        arrival.land(on: "wd:Q1")

        #expect(arrival.phase == .done)
    }

    @Test
    func `waits for the list to hold the focused element, then arrives once`() {
        var arrival: ListArrivalFocus = .init(focusURI: "wd:Q2")

        arrival.start(in: [], selectedURI: nil, reduceMotion: false)
        #expect(arrival.phase == .waiting("wd:Q2"))

        arrival.start(in: ["wd:Q1", "wd:Q2"], selectedURI: "wd:Q1", reduceMotion: false)
        #expect(arrival.phase == .arriving(.scroll("wd:Q2")))

        arrival.land(on: "wd:Q2")
        arrival.endHighlight()
        let again: ListArrivalFocus.Move? = arrival.start(in: ["wd:Q1", "wd:Q2", "wd:Q3"], selectedURI: "wd:Q2", reduceMotion: false)
        #expect(again == nil)
        #expect(arrival.phase == .done)
    }

    @Test
    func `leaves the haptic to the cover flow when the scroll moves the selection`() {
        var arrival: ListArrivalFocus = .init(focusURI: "wd:Q2")
        arrival.start(in: ["wd:Q1", "wd:Q2"], selectedURI: nil, reduceMotion: false)

        arrival.land(on: "wd:Q2")

        #expect(arrival.highlightedURI == "wd:Q2")
        #expect(arrival.landingFeedbackURI == nil)
    }

    @Test
    func `ticks as the halo lights when the focused element is the first`() {
        var arrival: ListArrivalFocus = .init(focusURI: "wd:Q1")
        arrival.start(in: ["wd:Q1", "wd:Q2"], selectedURI: nil, reduceMotion: false)

        arrival.land(on: "wd:Q1")

        #expect(arrival.landingFeedbackURI == "wd:Q1")
    }

    @Test
    func `ticks as the halo lights after a jump from no selection`() {
        var arrival: ListArrivalFocus = .init(focusURI: "wd:Q2")
        arrival.start(in: ["wd:Q1", "wd:Q2"], selectedURI: nil, reduceMotion: true)

        arrival.land(on: "wd:Q2")

        #expect(arrival.landingFeedbackURI == "wd:Q2")
    }

    @Test
    func `leaves the haptic to the cover flow when a jump moves an existing selection`() {
        var arrival: ListArrivalFocus = .init(focusURI: "wd:Q2")
        arrival.start(in: ["wd:Q1", "wd:Q2"], selectedURI: "wd:Q1", reduceMotion: true)

        arrival.land(on: "wd:Q2")

        #expect(arrival.landingFeedbackURI == nil)
    }
}
