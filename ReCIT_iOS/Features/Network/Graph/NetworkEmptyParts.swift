//
//  NetworkEmptyParts.swift
//  ReCIT_iOS
//
//  The parts of E1 (`602:18269`), for `NetworkEmptyView` to lay out — centred on « Vous » when
//  they fit, stacked in a scroll view when the text has grown past the screen.
//

import SwiftUI

/// The three parts of the empty state, in order — « Vous » first, which `MeCentredLayout`
/// centres. Several views rather than a stack, so whichever layout holds them places each.
struct NetworkEmptyParts: View {
    let username: String
    let imageUrl: String?

    var body: some View {
        NetworkMeNode(
            username: username,
            imageUrl: imageUrl
        )

        Text("network.graph.empty")
            .textStyle(.content300)
            .foregroundStyle(.foregroundSecondary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, .xLarge)

        NetworkFirstStepsCard()
    }
}
