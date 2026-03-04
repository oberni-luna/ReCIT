//
//  TransactionTypeLabel.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 05/02/2026.
//

import SwiftUI

struct TransactionTypeLabel: View {
    let transactionType: TransactionType

    var body: some View {
        Label(transactionType.label, systemImage: transactionType.systemImage)
            .labelStyle(LabelStyleWithSpacing(spacing: .xSmall))
    }
}

private extension TransactionType {
    var label: String {
        switch self {
        case .lending:
            String(localized: "transaction.type.lending")
        case .inventorying:
            String(localized: "transaction.type.inventorying")
        case .selling:
            String(localized: "transaction.type.selling")
        case .giving:
            String(localized: "transaction.type.giving")
        }
    }

    var systemImage: String {
        switch self {
        case .lending:
            "arrow.trianglehead.2.clockwise"
        case .inventorying:
            "book"
        case .selling:
            "banknote"
        case .giving:
            "gift"
        }
    }
}

#Preview {
    TransactionTypeLabel(transactionType: .inventorying)
}
