//
//  DonationModel.swift
//  ReCIT_iOS
//
//  Donations to Ex-libris, through the App Store: the three products of `DonationTier`, their
//  prices, the purchase, and the transactions to finish.
//
//  Built in `RootView` like every shared model, and for one more reason: a transaction can
//  arrive while no donation sheet is open — an Ask to Buy approved hours later, a purchase the
//  app was killed in the middle of — and StoreKit hands it over through `Transaction.updates`
//  only to whoever is listening. So the listening starts with the app, not with the sheet, and
//  every transaction that arrives is finished. An unfinished one is redelivered at every launch.
//
//  A donation unlocks nothing, which settles what verification is for here: nothing. A verified
//  and an unverified transaction are both finished and both thanked — refusing to thank someone
//  whose money the App Store took, on the grounds of a signature check that guards no content,
//  would be the one wrong answer.
//
//  `hasDonated` is kept on the device, like the card it hides: the Profil stops asking once
//  someone has given.
//

import Foundation
import StoreKit
import SwiftUI

@Observable
@MainActor
final class DonationModel {

    enum Catalog: Equatable {
        case loading
        /// The App Store did not answer, or does not sell the three products (yet).
        case unavailable
        case loaded
    }

    private(set) var catalog: Catalog = .loading
    /// Whether this device has seen a donation go through. Hides the Profil's card.
    private(set) var hasDonated: Bool {
        didSet { defaults.set(hasDonated, forKey: Self.hasDonatedKey) }
    }

    private var products: [DonationTier: Product] = [:]
    private let defaults: UserDefaults
    @ObservationIgnored private var updates: Task<Void, Never>?

    private static let hasDonatedKey: String = "donation.hasDonated"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        hasDonated = defaults.bool(forKey: Self.hasDonatedKey)
        updates = Task { [weak self] in
            for await result in StoreKit.Transaction.updates {
                await self?.settle(result)
            }
        }
    }

    /// What `tier` costs, written the way the sheet writes it — « 5 € ». Nil until the App Store
    /// has answered.
    func priceLabel(for tier: DonationTier) -> String? {
        guard let product = products[tier] else { return nil }
        return DonationPrice.label(for: product.price, format: product.priceFormatStyle)
    }

    /// Asks the App Store for the three products. Once they are known they are kept: a price does
    /// not change between two openings of the sheet.
    func loadProducts() async {
        guard catalog != .loaded else { return }
        catalog = .loading
        do {
            let found: [Product] = try await Product.products(for: DonationTier.allCases.map(\.productID))
            products = Dictionary(
                found.compactMap { product in DonationTier(productID: product.id).map { ($0, product) } },
                uniquingKeysWith: { first, _ in first }
            )
            // All three or none: a picker with one amount missing would offer a choice that is
            // not the one the design makes.
            catalog = products.count == DonationTier.allCases.count ? .loaded : .unavailable
        } catch {
            catalog = .unavailable
        }
    }

    /// Buys `tier` through `purchase` — SwiftUI's own purchase action, which knows which scene
    /// to present the App Store's sheet over.
    func donate(_ tier: DonationTier, with purchase: PurchaseAction) async -> DonationOutcome {
        guard let product = products[tier] else { return .failed }
        do {
            switch try await purchase(product) {
            case .success(let result):
                await settle(result)
                return .thanked
            case .pending:
                return .pending
            case .userCancelled:
                return .cancelled
            @unknown default:
                return .failed
            }
        } catch {
            return .failed
        }
    }

    /// Finishes a transaction, verified or not — see the file header — and remembers that this
    /// device has given.
    private func settle(_ result: VerificationResult<StoreKit.Transaction>) async {
        let transaction: StoreKit.Transaction = switch result {
        case .verified(let transaction), .unverified(let transaction, _): transaction
        }
        await transaction.finish()
        guard DonationTier(productID: transaction.productID) != nil else { return }
        hasDonated = true
    }
}
