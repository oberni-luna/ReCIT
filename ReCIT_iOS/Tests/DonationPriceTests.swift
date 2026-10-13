//
//  DonationPriceTests.swift
//  ReCIT_iOSTests
//
//  How the donation sheet writes a price: the storefront's currency, and no cents when there are
//  none.
//

import Testing
import Foundation
@testable import ReCIT_iOS

@Suite("Donation price")
struct DonationPriceTests {

    private let euros: Decimal.FormatStyle.Currency = .init(code: "EUR", locale: .init(identifier: "fr_FR"))
    private let dollars: Decimal.FormatStyle.Currency = .init(code: "USD", locale: .init(identifier: "en_US"))

    /// French formatting separates the amount from the sign with a narrow no-break space; the
    /// tests compare against plain spaces so they read as what is on screen.
    private func plain(_ label: String) -> String {
        label.replacing("\u{202F}", with: " ").replacing("\u{00A0}", with: " ")
    }

    @Test("A whole amount loses its cents")
    func wholeAmount() {
        #expect(plain(DonationPrice.label(for: 5, format: euros)) == "5 €")
        #expect(DonationPrice.label(for: 10, format: dollars) == "$10")
    }

    @Test("An amount with cents keeps both digits")
    func amountWithCents() {
        #expect(plain(DonationPrice.label(for: Decimal(string: "4.99")!, format: euros)) == "4,99 €")
        #expect(DonationPrice.label(for: Decimal(string: "2.5")!, format: dollars) == "$2.50")
    }
}
