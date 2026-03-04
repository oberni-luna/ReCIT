//
//  TransactionStateLabel.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 05/02/2026.
//

import SwiftUI

struct TransactionStateLabel: View {
    let state: UserTransaction.TransactionState

    var body: some View {
        Label(state.label, systemImage: state.systemImage)
            .labelStyle(LabelStyleWithSpacing(spacing: .xSmall))
    }
}

private extension UserTransaction.TransactionState {
    var label: String {
        switch self {
        case .requested:
            String(localized: "transaction.state.requested")
        case .accepted:
            String(localized: "transaction.state.accepted")
        case .confirmed:
            String(localized: "transaction.state.confirmed")
        case .returned:
            String(localized: "transaction.state.returned")
        case .declined:
            String(localized: "transaction.state.declined")
        }
    }
}

#Preview {
    TransactionStateLabel(state: .accepted)
}
