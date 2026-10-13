//
//  DonationTierTests.swift
//  ReCIT_iOSTests
//
//  The three amounts of the donation sheet, and the App Store products behind them.
//

import Testing
@testable import ReCIT_iOS

@Suite("Donation tiers")
struct DonationTierTests {

    @Test("The sheet offers three amounts, smallest first")
    func threeTiersInOrder() {
        #expect(DonationTier.allCases == [.coffee, .paperback, .hardcover])
    }

    @Test("The sheet opens on the middle amount")
    func preselectsTheMiddleOne() {
        #expect(DonationTier.preselected == .paperback)
    }

    @Test("Every tier has its own product, and finds itself back from it")
    func productIDsRoundTrip() {
        let ids: [String] = DonationTier.allCases.map(\.productID)

        #expect(Set(ids).count == ids.count)
        for tier in DonationTier.allCases {
            #expect(DonationTier(productID: tier.productID) == tier)
        }
    }

    @Test("A product that is not ours names no tier")
    func foreignProduct() {
        #expect(DonationTier(productID: "studio.lunabee.other") == nil)
    }

    @Test("Product identifiers only use what App Store Connect accepts")
    func identifiersAreValid() {
        let allowed: Set<Character> = .init("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._")
        for tier in DonationTier.allCases {
            #expect(tier.productID.allSatisfy(allowed.contains))
        }
    }
}
