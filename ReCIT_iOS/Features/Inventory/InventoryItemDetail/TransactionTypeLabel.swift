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
            "À prêter"
        case .inventorying:
            "Inventorié"
        case .selling:
            "À vendre"
        case .giving:
            "À donner"
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
