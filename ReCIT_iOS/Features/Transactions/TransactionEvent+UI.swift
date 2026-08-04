//
//  TransactionEvent+UI.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 04/08/2026.
//

import SwiftUI

extension TransactionEvent {
    /// The button label shown to the user for this action.
    var label: String {
        switch self {
        case .request:
            String(localized: "transaction.action.request")
        case .accept:
            String(localized: "transaction.action.accept")
        case .reject:
            String(localized: "transaction.action.decline")
        case .cancel:
            String(localized: "transaction.action.cancel")
        case .confirm:
            String(localized: "transaction.action.confirm")
        case .close:
            String(localized: "transaction.action.complete")
        }
    }
}
