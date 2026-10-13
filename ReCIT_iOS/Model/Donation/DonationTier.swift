//
//  DonationTier.swift
//  ReCIT_iOS
//
//  The three amounts the donation sheet offers — un café, un poche, un grand format — and the
//  App Store product behind each. Consumables: a donation can be made again, and unlocks
//  nothing.
//
//  The identifiers are the contract with App Store Connect, where the three products have to
//  exist under exactly these names (and in `Donations.storekit` for the simulator). Product
//  identifiers allow letters, digits, underscores and periods only — hence `nouveaurecit`,
//  without the bundle identifier's hyphen.
//
//  What a tier costs is *not* here: the price is the App Store's, per storefront, and only
//  StoreKit knows it. See `DonationPrice`.
//

import Foundation

enum DonationTier: CaseIterable, Hashable {
    /// Three euros, or the storefront's equivalent.
    case coffee
    /// Five.
    case paperback
    /// Ten.
    case hardcover

    /// The tier the sheet opens on — the middle one, as in the design.
    static let preselected: DonationTier = .paperback

    var productID: String {
        switch self {
        case .coffee: "studio.lunabee.nouveaurecit.donation.coffee"
        case .paperback: "studio.lunabee.nouveaurecit.donation.paperback"
        case .hardcover: "studio.lunabee.nouveaurecit.donation.hardcover"
        }
    }

    /// The tier a product identifier names, if it is one of ours.
    init?(productID: String) {
        guard let tier = Self.allCases.first(where: { $0.productID == productID }) else { return nil }
        self = tier
    }
}
