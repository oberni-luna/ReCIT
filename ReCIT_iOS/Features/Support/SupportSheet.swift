//
//  SupportSheet.swift
//  ReCIT_iOS
//
//  « Faire un don », the sheet the Profil's card opens. On white, top to bottom: the app's
//  picture on its wash, « Soutenir Ex-libris », where the money goes (50 / 50 with inventaire.io),
//  the three amounts, and the small print — a one-off, no subscription, the app whole either way,
//  the App Store's cut. « Donner » stays pinned under it all, with the chosen price on it.
//
//  What happens after the press is `DonationModel`'s, and the sheet only says how it ended: a
//  thank-you, or that the payment waits on an approval, in place of the form; a line in red over
//  the button if it failed; nothing at all if the person backed out of the App Store's sheet.
//
//  The prices are the App Store's. Until it has answered, the tiles read « — » and the button is
//  off; if it does not answer — no network, products not on sale yet — a sentence says donations
//  are unavailable, and the button stays off.
//
//  See the Figma frame `PA · Paywall · L'étagère` (`588:17950`).
//

import SwiftUI
import StoreKit

struct SupportSheet: View {
    @Environment(DonationModel.self) private var donationModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.purchase) private var purchase

    @State private var selection: DonationTier = .preselected
    @State private var closing: SupportClosingView.Reason?
    @State private var hasFailed: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                Group {
                    if let closing {
                        SupportClosingView(reason: closing)
                            .transition(.opacity)
                    } else {
                        form
                    }
                }
                .padding(.top, .small)
                .padding(.bottom, .large)
            }
            .safeAreaInset(edge: .bottom) {
                footer
            }
            .background(.backgroundDefault)
            .navigationTitle("support.sheet.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("support.sheet.close", systemImage: "xmark") {
                        dismiss()
                    }
                    .accessibilityIdentifier("e2e.support.close")
                }
            }
        }
        .task {
            await donationModel.loadProducts()
        }
    }

    private var form: some View {
        VStack(spacing: .large) {
            SupportIllustration()

            VStack(spacing: .small) {
                Text("support.headline")
                    .textStyle(.title200)
                    .foregroundStyle(.foregroundDefault)
                    .accessibilityAddTraits(.isHeader)
                Text("support.tagline")
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundSecondary)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, .large)

            SupportSplitCard()
                .padding(.horizontal, .medium)

            SupportAmountPicker(selection: $selection) { tier in
                donationModel.priceLabel(for: tier)
            }
            .padding(.horizontal, .medium)

            smallPrint
                .padding(.horizontal, .large)
        }
    }

    /// The reassurance, or — when the App Store has not answered — why there is nothing to buy.
    private var smallPrint: some View {
        HStack(alignment: .firstTextBaseline, spacing: .small) {
            Image(systemName: donationModel.catalog == .unavailable ? "exclamationmark.circle" : "checkmark.circle")
                .accessibilityHidden(true)
            Text(donationModel.catalog == .unavailable ? "support.unavailable" : "support.reassurance")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .textStyle(.footnote200)
        .foregroundStyle(.foregroundSecondary)
    }

    private var footer: some View {
        VStack(spacing: .small) {
            if hasFailed {
                Text("support.failed")
                    .textStyle(.footnote200)
                    .foregroundStyle(.foregroundError)
                    .multilineTextAlignment(.center)
            }
            if closing == nil {
                AsyncButton(action: donate, actionOptions: [.disableButton, .showProgressView]) {
                    donateLabel
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.primary())
                .disabled(donationModel.catalog != .loaded)
                .accessibilityIdentifier("e2e.support.donate")
            } else {
                Button {
                    dismiss()
                } label: {
                    Text("support.sheet.close")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.primary())
            }
        }
        .padding(.horizontal, .medium)
        .padding(.vertical, .small)
        .background(.backgroundDefault)
    }

    @ViewBuilder
    private var donateLabel: some View {
        if let price = donationModel.priceLabel(for: selection) {
            Text("support.donate \(price)")
        } else {
            Text("support.donate")
        }
    }

    private func donate() async {
        hasFailed = false
        switch await donationModel.donate(selection, with: purchase) {
        case .thanked:
            withAnimation { closing = .thanked }
        case .pending:
            withAnimation { closing = .pending }
        case .cancelled:
            break
        case .failed:
            hasFailed = true
        }
    }
}

#Preview {
    SupportSheet()
        .environment(DonationModel())
}
