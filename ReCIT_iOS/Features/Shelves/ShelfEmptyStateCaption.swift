//
//  ShelfEmptyStateCaption.swift
//  ReCIT_iOS
//
//  The two lines above the empty shelf: the step the user is at, then one sentence saying
//  what the tags on the plank are for. Written on the screen rather than on paper — the paper
//  is kept for what can be pressed.
//

import SwiftUI

struct ShelfEmptyStateCaption: View {
    let errand: ShelfEmptyStateErrand

    var body: some View {
        VStack(spacing: .xSmall) {
            Text(errand.heading)
                .textStyle(.content400Bold)
                .foregroundStyle(.foregroundDefault)
                .accessibilityAddTraits(.isHeader)
            Text(errand.body)
                .textStyle(.content300)
                .foregroundStyle(.foregroundSecondary)
        }
        .multilineTextAlignment(.center)
    }
}
