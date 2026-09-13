//
//  ReportMailDraftTests.swift
//  ReCIT_iOSTests
//
//  A report is a mailto: URL and nothing else, so what is worth testing is that the URL
//  survives the characters a username or a message can legitimately contain.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@Suite("Report mail draft")
struct ReportMailDraftTests {
    private func draft(
        username: String = "alice",
        userId: String = "usr_1",
        transactionId: String? = nil
    ) -> ReportMailDraft {
        .init(
            reportedUsername: username,
            reportedUserId: userId,
            transactionId: transactionId,
            reporterUsername: "bob",
            appVersion: "1.4 (23)"
        )
    }

    @Test("The mail goes to the moderation mailbox")
    func addressesTheMailbox() throws {
        let url: URL = try #require(draft().mailtoURL)
        #expect(url.scheme == "mailto")
        #expect(url.absoluteString.hasPrefix("mailto:ex-libris@lunabee.com?"))
    }

    @Test("The subject names the reported member")
    func subjectNamesTheMember() {
        #expect(draft().subject.contains("alice"))
    }

    @Test("The transaction id joins the subject only when there is one")
    func subjectCarriesTheTransaction() {
        #expect(draft().subject.contains("tx_9") == false)
        #expect(draft(transactionId: "tx_9").subject.contains("tx_9"))
    }

    @Test("The body carries the ids a reporter would never copy by hand")
    func bodyCarriesTheFacts() {
        let body: String = draft(transactionId: "tx_9").body
        #expect(body.contains("usr_1"))
        #expect(body.contains("tx_9"))
        #expect(body.contains("bob"))
        #expect(body.contains("1.4 (23)"))
    }

    @Test("The body leaves out the exchange when the report is about the person")
    func bodyOmitsTheTransaction() {
        #expect(draft().body.contains("tx_9") == false)
    }

    @Test("Query separators inside a username are escaped, not swallowed")
    func escapesQuerySeparators() throws {
        let url: URL = try #require(draft(username: "a&b=c+d?e#f").mailtoURL)
        let tail: String = url.absoluteString
        #expect(tail.contains("a&b") == false)
        #expect(tail.contains("%26"))
        #expect(tail.contains("%2B"))
        // Two query items, not five.
        #expect(tail.filter { $0 == "&" }.count == 1)
    }

    @Test("A newline in the body survives as an escape")
    func escapesNewlines() throws {
        let url: URL = try #require(draft().mailtoURL)
        #expect(url.absoluteString.contains("%0A"))
    }
}
