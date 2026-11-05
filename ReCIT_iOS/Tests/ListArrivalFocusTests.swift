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
    func `scrolls to the focused element, then rings it once centred`() {
        var arrival: ListArrivalFocus = .init(focusURI: "wd:Q2")

        arrival.start(in: ["wd:Q1", "wd:Q2"], reduceMotion: false)
        #expect(arrival.phase == .arriving(.scroll("wd:Q2")))
        #expect(arrival.highlightedURI == nil)

        arrival.land(on: "wd:Q2")
        #expect(arrival.highlightedURI == "wd:Q2")

        arrival.endHighlight()
        #expect(arrival.phase == .done)
    }

    @Test
    func `does nothing for a list opened without a focus`() {
        var arrival: ListArrivalFocus = .init(focusURI: nil)

        arrival.start(in: ["wd:Q1", "wd:Q2"], reduceMotion: false)
        arrival.land(on: "wd:Q1")

        #expect(arrival.phase == .done)
        #expect(arrival.highlightedURI == nil)
    }

    @Test
    func `jumps straight to the focused element under Reduce Motion`() {
        var arrival: ListArrivalFocus = .init(focusURI: "wd:Q2")

        arrival.start(in: ["wd:Q1", "wd:Q2"], reduceMotion: true)

        #expect(arrival.phase == .arriving(.jump("wd:Q2")))
    }

    @Test
    func `puts the halo out when the reader picks another element`() {
        var arrival: ListArrivalFocus = .init(focusURI: "wd:Q2")
        arrival.start(in: ["wd:Q1", "wd:Q2"], reduceMotion: false)
        arrival.land(on: "wd:Q2")

        arrival.select("wd:Q2")
        #expect(arrival.highlightedURI == "wd:Q2")

        arrival.select("wd:Q1")
        #expect(arrival.phase == .done)
    }

    @Test
    func `rings nothing when the reader moved away during the scroll`() {
        var arrival: ListArrivalFocus = .init(focusURI: "wd:Q2")
        arrival.start(in: ["wd:Q1", "wd:Q2"], reduceMotion: false)

        arrival.land(on: "wd:Q1")

        #expect(arrival.phase == .done)
    }

    @Test
    func `waits for the list to hold the focused element, then arrives once`() {
        var arrival: ListArrivalFocus = .init(focusURI: "wd:Q2")

        arrival.start(in: [], reduceMotion: false)
        #expect(arrival.phase == .waiting("wd:Q2"))

        arrival.start(in: ["wd:Q1", "wd:Q2"], reduceMotion: false)
        #expect(arrival.phase == .arriving(.scroll("wd:Q2")))

        arrival.land(on: "wd:Q2")
        arrival.endHighlight()
        arrival.start(in: ["wd:Q1", "wd:Q2", "wd:Q3"], reduceMotion: false)
        #expect(arrival.phase == .done)
    }
}
