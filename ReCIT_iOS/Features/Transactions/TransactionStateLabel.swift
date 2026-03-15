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
        Label(state.name, systemImage: state.systemImage)
            .labelStyle(.secondaryTag)
    }
}

private extension UserTransaction.TransactionState {
    var name: String {
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
        case .cancelled:
            String(localized: "transaction.state.cancelled")
        }
    }
}

#Preview {
    TransactionStateLabel(state: .accepted)
}
