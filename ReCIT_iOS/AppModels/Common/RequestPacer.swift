//
//  RequestPacer.swift
//  ReCIT_iOS
//
//  Runs requests one after the other, a minimum interval apart.
//
//  `PUT /api/user` is rate-limited per account with `minTimeBetweenRequests: 1000`: a second
//  request less than a second after the first is refused with a `429`, whatever it changes. A
//  profile is saved one attribute per request, and two switches flipped in a row in « Notifications
//  par e-mail » are two requests — sent as they come, the second would fail and its switch would
//  flip back. Through the pacer they queue, and each waits for its slot.
//

import Foundation

@MainActor
final class RequestPacer {
    private let interval: Duration
    private let clock: ContinuousClock = .init()
    private var lastStart: ContinuousClock.Instant?
    /// The last operation queued, done or not: the next one waits for it.
    private var tail: Task<Void, Never>?

    init(interval: Duration) {
        self.interval = interval
    }

    func run<T: Sendable>(_ operation: @escaping @MainActor () async throws -> T) async throws -> T {
        let previous: Task<Void, Never>? = tail
        let current: Task<T, Error> = Task {
            await previous?.value
            await self.waitForSlot()
            return try await operation()
        }
        tail = Task {
            _ = try? await current.value
        }
        return try await current.value
    }

    private func waitForSlot() async {
        if let lastStart {
            let next: ContinuousClock.Instant = lastStart.advanced(by: interval)
            if next > clock.now {
                try? await clock.sleep(until: next)
            }
        }
        lastStart = clock.now
    }
}
