//
//  TransactionTypeLabel.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 05/02/2026.
//

import SwiftUI

extension TransactionType {
    var localizedTitle: String {
        switch self {
        case .lending: String(localized: "transaction.type.lending")
        case .inventorying: String(localized: "transaction.type.inventorying")
        case .selling: String(localized: "transaction.type.selling")
        case .giving: String(localized: "transaction.type.giving")
        }
    }

    var image: Image {
        switch self {
        case .lending: Image(.lending)
        case .inventorying: Image(.inventorying)
        case .selling: Image(.selling)
        case .giving: Image(.giving)
        }
    }

    /// A `Label` composed of the transaction type's icon and localized title,
    /// ready to be styled with `.labelStyle(.tag)`.
    var label: some View {
        Label { Text(localizedTitle) } icon: { image.resizable().scaledToFit() }
    }
}
