//
//  EmailInvitationFailureTests.swift
//  ReCIT_iOSTests
//
//  Created by Olivier Berni on 18/11/2026.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@Suite
struct EmailInvitationFailureTests {
    private static func french(_ resource: LocalizedStringResource) -> String {
        var resource: LocalizedStringResource = resource
        resource.locale = .init(identifier: "fr")
        return String(localized: resource)
    }

    @Test
    func `a 429 is the quota, with a sentence of its own`() throws {
        let failure: EmailInvitationFailure = .init(error: NetworkError.badStatus(code: 429, message: nil))

        guard case .rateLimited = failure else {
            Issue.record("Expected .rateLimited, got \(failure)")
            return
        }
        let message: LocalizedStringResource = try #require(failure.message)
        #expect(Self.french(message) == "Trop d'invitations envoyées. Réessayez plus tard.")
    }

    @Test(
        arguments: [
            NetworkError.badStatus(code: 500, message: "oops"),
            NetworkError.badStatus(code: 400, message: "you can't send more than 50 invitations at a time"),
            NetworkError.transport(underlying: URLError(.notConnectedToInternet))
        ]
    )
    func `anything else keeps its error and has no sentence of its own`(error: NetworkError) {
        let failure: EmailInvitationFailure = .init(error: error)

        guard case let .other(kept) = failure else {
            Issue.record("Expected .other, got \(failure)")
            return
        }
        #expect(kept is NetworkError)
        #expect(failure.message == nil)
    }
}
