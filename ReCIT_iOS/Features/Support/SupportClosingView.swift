//
//  SupportClosingView.swift
//  ReCIT_iOS
//
//  What the donation sheet says once « Donner » has done its work: thank you, or — when the
//  payment waits on someone else's approval — that it will count once given. Same picture as the
//  sheet opened on, so the ending reads as the same page turned.
//

import SwiftUI

struct SupportClosingView: View {
    enum Reason {
        case thanked
        case pending
    }

    let reason: Reason

    var body: some View {
        VStack(spacing: .large) {
            SupportIllustration()
            VStack(spacing: .small) {
                Text(title)
                    .textStyle(.title200)
                    .foregroundStyle(.foregroundDefault)
                    .accessibilityAddTraits(.isHeader)
                Text(detail)
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundSecondary)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, .large)
        }
        .accessibilityIdentifier("e2e.support.closing")
    }

    private var title: LocalizedStringKey {
        switch reason {
        case .thanked: "support.thanks.title"
        case .pending: "support.pending.title"
        }
    }

    private var detail: LocalizedStringKey {
        switch reason {
        case .thanked: "support.thanks.body"
        case .pending: "support.pending.body"
        }
    }
}

#Preview {
    SupportClosingView(reason: .thanked)
}
