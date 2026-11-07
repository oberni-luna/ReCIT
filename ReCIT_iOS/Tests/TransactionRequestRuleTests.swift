//
//  TransactionRequestRuleTests.swift
//  ReCIT_iOSTests
//
//  Created by Olivier Berni on 07/11/2026.
//

import Testing
@testable import ReCIT_iOS

@Suite
struct TransactionRequestRuleTests {
    @Test
    func `offers every friend's copy when I own none`() {
        let rule: TransactionRequestRule = .init(
            copies: [("alex", "isbn:1"), ("claire", "isbn:2")],
            myUserId: "me"
        )

        #expect(rule.isRequestOffered(forEditionURI: "isbn:1"))
        #expect(rule.isRequestOffered(forEditionURI: "isbn:2"))
    }

    @Test
    func `offers the copies of another edition than mine`() {
        let rule: TransactionRequestRule = .init(
            copies: [("me", "isbn:1"), ("alex", "isbn:2"), ("claire", "isbn:3")],
            myUserId: "me"
        )

        #expect(rule.isRequestOffered(forEditionURI: "isbn:2"))
        #expect(rule.isRequestOffered(forEditionURI: "isbn:3"))
    }

    @Test
    func `does not offer a copy of the edition I own`() {
        let rule: TransactionRequestRule = .init(
            copies: [("me", "isbn:1"), ("alex", "isbn:1")],
            myUserId: "me"
        )

        #expect(rule.isRequestOffered(forEditionURI: "isbn:1") == false)
    }

    @Test
    func `offers every copy while I am not known yet`() {
        let rule: TransactionRequestRule = .init(
            copies: [("alex", "isbn:1")],
            myUserId: nil
        )

        #expect(rule.isRequestOffered(forEditionURI: "isbn:1"))
    }
}
