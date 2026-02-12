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
            "Demande"
        case .accepted:
            "Accepté"
        case .confirmed:
            "Confirmé"
        case .returned:
            "Retourné"
        }
    }
}

#Preview {
    TransactionStateLabel(state: .accepted)
}
