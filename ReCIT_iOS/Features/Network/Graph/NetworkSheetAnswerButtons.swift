//
//  NetworkSheetAnswerButtons.swift
//  ReCIT_iOS
//
//  Accepter and Refuser in a sheet of the Réseau graph (PRD 0019, Q26, issue 0108): the pills of
//  the invitation rows, side by side — the « yes » prominent, the « no » tinted and never red,
//  since declining destroys nothing.
//

import SwiftUI

struct NetworkSheetAnswerButtons: View {
    let onAnswer: (NetworkSheetAnswer) -> Void

    var body: some View {
        HStack(spacing: .small) {
            Button("network.invitation.accept") {
                onAnswer(.accept)
            }
            .buttonStyle(.pill(.prominent))
            .accessibilityIdentifier("e2e.network.graph.sheet.accept")

            Button("network.invitation.refuse") {
                onAnswer(.refuse)
            }
            .buttonStyle(.pill(.tinted))
            .accessibilityIdentifier("e2e.network.graph.sheet.refuse")
        }
    }
}

#Preview {
    NetworkSheetAnswerButtons { _ in }
        .padding()
}
