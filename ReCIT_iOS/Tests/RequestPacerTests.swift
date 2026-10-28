//
//  RequestPacerTests.swift
//  ReCIT_iOSTests
//
//  `PUT /api/user` refuses two requests less than a second apart. The pacer is what keeps two
//  switches flipped in a row from failing the second: it runs them in order, spaced.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@MainActor
@Suite("RequestPacer")
struct RequestPacerTests {

    @Test("Operations run one after the other, in the order they were queued")
    func runsInOrder() async throws {
        let pacer: RequestPacer = .init(interval: .zero)
        var log: [String] = []

        async let first: Void = pacer.run {
            log.append("first start")
            try await Task.sleep(for: .milliseconds(50))
            log.append("first end")
        }
        async let second: Void = pacer.run {
            log.append("second")
        }
        _ = try await (first, second)

        #expect(log == ["first start", "first end", "second"])
    }

    @Test("A second operation waits for the interval")
    func waitsForTheInterval() async throws {
        let pacer: RequestPacer = .init(interval: .milliseconds(200))
        let clock: ContinuousClock = .init()
        let start: ContinuousClock.Instant = clock.now

        try await pacer.run {}
        try await pacer.run {}

        #expect(clock.now - start >= .milliseconds(200))
    }

    @Test("A failure does not hold the queue up")
    func failureDoesNotBlock() async throws {
        let pacer: RequestPacer = .init(interval: .zero)

        await #expect(throws: NetworkError.self) {
            try await pacer.run { throw NetworkError.badResponse }
        }
        let value: Int = try await pacer.run { 42 }
        #expect(value == 42)
    }
}
