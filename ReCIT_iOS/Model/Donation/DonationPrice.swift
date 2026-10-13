//
//  DonationPrice.swift
//  ReCIT_iOS
//
//  How an amount is written on the donation sheet: in the storefront's currency and format, as
//  StoreKit gives them, but without the cents when there are none — « 5 € », not « 5,00 € ».
//  The design speaks of a coffee at three euros; a price tag reading « 3,00 € » is a till
//  receipt. A price that does have cents keeps them: « 4,99 € » stays « 4,99 € ».
//
//  Pure, so the rule can be tested: StoreKit's `Product` cannot be built in a test, but its
//  `price` and `priceFormatStyle` are plain Foundation values.
//

import Foundation

enum DonationPrice {
    static func label(
        for price: Decimal,
        format: Decimal.FormatStyle.Currency
    ) -> String {
        price.formatted(format.precision(.fractionLength(isWhole(price) ? 0 : 2)))
    }

    private static func isWhole(_ price: Decimal) -> Bool {
        var value: Decimal = price
        var rounded: Decimal = .zero
        NSDecimalRound(&rounded, &value, 0, .plain)
        return rounded == price
    }
}
