//
//  NetworkSegmentTests.swift
//  ReCIT_iOSTests
//
//  The Réseau tab reopens on the segment chosen last, on « Tout » the very first time, and on
//  Amis when the value kept is one this build does not know — « all » written by a `DEBUG` build
//  and read by a Release one, where « Tout » is not compiled (PRD 0019, Q12, Q47).
//

import Testing
@testable import ReCIT_iOS

@MainActor
@Suite("NetworkSegment")
struct NetworkSegmentTests {

    @Test("The first launch opens on Tout where it exists, on Amis otherwise")
    func firstLaunch() {
        #if DEBUG
        #expect(NetworkSegment.restored(from: nil) == .all)
        #else
        #expect(NetworkSegment.restored(from: nil) == .friends)
        #endif
        #expect(NetworkSegment.restored(from: nil) == NetworkSegment.firstLaunch)
    }

    @Test("Every segment of the build reopens as itself", arguments: NetworkSegment.allCases)
    func roundTrip(segment: NetworkSegment) {
        #expect(NetworkSegment.restored(from: segment.rawValue) == segment)
    }

    /// The path a stored « all » takes in Release: the raw value maps to no case of the build.
    @Test("A value the build does not know falls back on Amis", arguments: ["constellation", "", "ALL", "Tout"])
    func unknownValue(rawValue: String) {
        #expect(NetworkSegment.restored(from: rawValue) == .friends)
    }

    #if DEBUG
    @Test("Tout is the first segment, and is stored as « all »")
    func allComesFirst() {
        #expect(NetworkSegment.allCases == [.all, .friends, .groups])
        #expect(NetworkSegment.all.rawValue == "all")
    }

    @Test("The graph is on white, the lists on their grey")
    func grounds() {
        #expect(NetworkSegment.all.ground == .backgroundDefault)
        #expect(NetworkSegment.friends.ground == .backgroundGrouped)
        #expect(NetworkSegment.groups.ground == .backgroundGrouped)
    }
    #else
    @Test("« all », kept by a DEBUG build, reopens on Amis")
    func allFallsBackInRelease() {
        #expect(NetworkSegment.restored(from: "all") == .friends)
    }
    #endif
}
