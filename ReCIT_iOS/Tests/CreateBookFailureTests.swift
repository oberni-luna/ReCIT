//
//  CreateBookFailureTests.swift
//  ReCIT_iOSTests
//
//  What a failed contribution says. The mapping from a status code to a sentence is a
//  decision, and the sentence a reader acts on: told wrongly that the book might exist, they
//  do not press the button again, and the book stays in their hand for nothing.
//
//  See PRD 0015.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@Suite("CreateBookFailure")
struct CreateBookFailureTests {

    @Test("An expired session is named as one, rather than as a status code")
    func unauthorisedNeedsAnAccount() {
        #expect(CreateBookFailure(error: NetworkError.badStatus(code: 401, message: nil)) == .needsAccount)
        #expect(CreateBookFailure(error: NetworkError.badStatus(code: 403, message: nil)) == .needsAccount)
    }

    @Test("An entry the server would not take is a refusal, not a network failure")
    func badRequestIsARefusal() {
        #expect(CreateBookFailure(error: NetworkError.badStatus(code: 400, message: "invalid isbn")) == .refused)
    }

    @Test("A server that broke, or never answered, is the case a retry is for")
    func serverAndTransportFailuresAreNetwork() {
        #expect(CreateBookFailure(error: NetworkError.badStatus(code: 500, message: nil)) == .network)
        #expect(CreateBookFailure(error: NetworkError.badResponse) == .network)
        #expect(CreateBookFailure(error: NetworkError.transport(underlying: URLError(.notConnectedToInternet))) == .network)
    }

    @Test("An error from outside the network layer is not read as a refusal")
    func unknownErrorsAreNetwork() {
        struct Nothing: Error {}
        #expect(CreateBookFailure(error: Nothing()) == .network)
    }

    /// A refused entry is not going to be accepted by asking twice, and an account cannot be
    /// obtained from this sheet.
    @Test("Only the failure a retry can fix offers one")
    func onlyNetworkFailuresOfferARetry() {
        #expect(CreateBookFailure.network.isWorthRetrying)
        #expect(CreateBookFailure.refused.isWorthRetrying == false)
        #expect(CreateBookFailure.needsAccount.isWorthRetrying == false)
    }
}
