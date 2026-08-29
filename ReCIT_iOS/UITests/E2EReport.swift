//
//  E2EReport.swift
//  ReCIT_iOSUITests
//
//  What the end-to-end run leaves behind: one line per step — what it did, what it acted on,
//  a screenshot of the screen it ended on, and OK or KO with the reason when it is KO.
//
//  **It is written to disk after every step, not at the end.** A scenario that drives the real
//  app against the real server can hang or crash halfway, and a report that only exists once
//  the last step passes is a report you never get on the runs you most want to read. Each step
//  rewrites `report.json` in full; the PNG beside it is already there.
//
//  It lands in the *runner's* `Documents/e2e-report/`, because a UI test runs inside the
//  simulator and has no other writable place the host can find. `scripts/e2e.sh` pulls the
//  folder out with `xcrun simctl get_app_container` and renders it as HTML. The same steps are
//  also attached to the `.xcresult`, so a run started from Xcode reads the same way.
//
//  See `docs/features/0012-end-to-end-scenario.md`.
//

import Foundation
import XCTest

/// How a step ended.
enum E2EStatus: String, Encodable {
    case ok = "OK"
    case ko = "KO"
    /// Never attempted, because something it depended on failed. Reported rather than dropped:
    /// a scenario that stops after step 4 must say the last six were not run, not go quiet.
    case skipped = "SKIP"
}

/// One line of the report.
struct E2EStep: Encodable {
    let index: Int
    let title: String
    /// What the step acted on, in the user's terms — the book that was added, the shelf that was
    /// named. This is the half that makes the report checkable rather than merely green.
    let detail: String
    let status: E2EStatus
    /// Why it is KO. Absent otherwise.
    let message: String?
    /// File name of the screenshot beside `report.json`, if one was taken.
    let screenshot: String?
    let durationSeconds: Double
}

/// The run as a whole.
struct E2ERun: Encodable {
    let scenario: String
    let startedAt: String
    let finishedAt: String?
    let device: String
    let account: String
    let steps: [E2EStep]
    let okCount: Int
    let koCount: Int
    let skippedCount: Int
}

@MainActor
final class E2EReport {
    /// Where the whole thing lands, inside the runner's container.
    let directory: URL

    private let scenario: String
    private let device: String
    private let account: String
    private let startedAt: Date
    private var steps: [E2EStep] = []

    private let iso: ISO8601DateFormatter = {
        let formatter: ISO8601DateFormatter = .init()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    init(scenario: String, device: String, account: String) {
        self.scenario = scenario
        self.device = device
        self.account = account
        startedAt = .now

        let documents: URL = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
        directory = documents.appending(path: "e2e-report")

        // Cleared rather than added to: a run reports on itself, and yesterday's screenshots
        // sitting between today's steps would be read as today's.
        try? FileManager.default.removeItem(at: directory)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    /// Whether anything has gone wrong so far. The scenario reads it to decide whether the next
    /// step can be attempted at all.
    var hasFailed: Bool {
        steps.contains { $0.status == .ko }
    }

    var failureCount: Int {
        steps.count { $0.status == .ko }
    }

    // MARK: - Recording

    /// Files one finished step and rewrites the report.
    func record(
        title: String,
        detail: String,
        status: E2EStatus,
        message: String? = nil,
        duration: Double,
        screenshot: Data?
    ) {
        let index: Int = steps.count + 1
        var fileName: String?

        if let screenshot {
            let name: String = "\(String(format: "%02d", index))-\(Self.slug(title)).png"
            try? screenshot.write(to: directory.appending(path: name))
            fileName = name
        }

        steps.append(
            .init(
                index: index,
                title: title,
                detail: detail,
                status: status,
                message: message,
                screenshot: fileName,
                durationSeconds: (duration * 100).rounded() / 100
            )
        )

        flush(finished: false)
    }

    /// Writes the final state, with the end timestamp.
    func finish() {
        flush(finished: true)
    }

    // MARK: - Private

    private func flush(finished: Bool) {
        let run: E2ERun = .init(
            scenario: scenario,
            startedAt: iso.string(from: startedAt),
            finishedAt: finished ? iso.string(from: .now) : nil,
            device: device,
            account: account,
            steps: steps,
            okCount: steps.count { $0.status == .ok },
            koCount: steps.count { $0.status == .ko },
            skippedCount: steps.count { $0.status == .skipped }
        )

        let encoder: JSONEncoder = .init()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(run) else { return }

        try? data.write(to: directory.appending(path: "report.json"))
    }

    /// A file-name-safe form of the step title, so the screenshots read in order and by name.
    private static func slug(_ title: String) -> String {
        let allowed: CharacterSet = .alphanumerics
        let folded: String = title.folding(options: [.diacriticInsensitive], locale: .init(identifier: "fr_FR"))
        let scalars: String = .init(
            folded.unicodeScalars.map { allowed.contains($0) ? Character($0) : "-" }
        )
        return scalars
            .lowercased()
            .split(separator: "-", omittingEmptySubsequences: true)
            .prefix(6)
            .joined(separator: "-")
    }
}
