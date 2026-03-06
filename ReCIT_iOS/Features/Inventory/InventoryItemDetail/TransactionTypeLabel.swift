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
        HStack(spacing: .xSmall) {
            transactionType.image
                .resizable()
                .frame(width: 16, height: 16)

            Text(transactionType.label)
                .textStyle(.action200)
        }
        .padding(.horizontal, .small)
        .padding(.vertical, .xSmall)
        .cornerRadius(.minimal)
        .background(.backgroundTinted)
        .foregroundStyle(.foregroundTinted)
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

    var image: Image {
        switch self {
        case .lending:
            Image(.lending)
        case .inventorying:
            Image(.inventorying)
        case .selling:
            Image(.selling)
        case .giving:
            Image(.giving)
        }
    }
}

#Preview {
    TransactionTypeLabel(transactionType: .inventorying)
}
