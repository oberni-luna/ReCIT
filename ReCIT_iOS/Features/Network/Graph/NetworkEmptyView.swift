//
//  NetworkEmptyView.swift
//  ReCIT_iOS
//
//  « Tout » with nobody and nothing to draw around me — E1 (`602:18269`, PRD 0019, Q39): « Vous »
//  alone at the centre, a sentence that says what will come there, and the two first steps. No
//  zoom controls and no counter: there is nothing to zoom on or to count.
//
//  « Vous » sits where the graph will put it, so the first friend or group arrives around it
//  rather than moving it. At large text sizes it climbs to keep the steps on screen, and only when
//  even the parts stacked tight do not fit does the state scroll.
//

import SwiftUI

struct NetworkEmptyView: View {
    let username: String
    let imageUrl: String?

    var body: some View {
        ViewThatFits(in: .vertical) {
            MeCentredLayout(
                spacing: .large,
                leadAnchor: NetworkGraphMetrics.meSide / 2
            ) {
                NetworkEmptyParts(
                    username: username,
                    imageUrl: imageUrl
                )
            }
            .padding(.horizontal, .medium)

            ScrollView {
                VStack(spacing: .large) {
                    NetworkEmptyParts(
                        username: username,
                        imageUrl: imageUrl
                    )
                }
                .padding(.all, .medium)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }
}

#Preview {
    NavigationStack {
        NetworkEmptyView(username: "olivier_berni", imageUrl: nil)
            .background(.backgroundDefault)
    }
}
