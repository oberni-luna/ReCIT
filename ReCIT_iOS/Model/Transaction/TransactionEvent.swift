//
//  TransactionEvent.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 04/08/2026.
//

import Foundation

/// A user-triggered verb that drives a transaction from one state to the next.
///
/// Distinct from `UserTransaction.TransactionState`: the event is the action the
/// user takes (`accept`), the state is the result of taking it (`accepted`).
enum TransactionEvent: String, CaseIterable, Hashable {
    case request
    case accept
    case reject
    case cancel
    case confirm
    case close

    /// The "forward", happy-path moves that the UI surfaces as the primary
    /// default action. Everything else (cancel, reject) is a secondary action.
    var isDefault: Bool {
        switch self {
        case .accept, .confirm, .close:
            true
        case .request, .reject, .cancel:
            false
        }
    }
}
