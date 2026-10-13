//
//  DonationTier+Caption.swift
//  ReCIT_iOS
//
//  What each amount is worth, in things a reader buys: un café, un poche, un grand format. The
//  words under the price on the donation sheet. Kept out of `DonationTier`, which is the App
//  Store's contract and has no business with SwiftUI.
//

import SwiftUI

extension DonationTier {
    var caption: LocalizedStringKey {
        switch self {
        case .coffee: "support.tier.coffee"
        case .paperback: "support.tier.paperback"
        case .hardcover: "support.tier.hardcover"
        }
    }
}
