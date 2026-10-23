//
//  TransactionState+UI.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 04/08/2026.
//

import SwiftUI

extension UserTransaction.TransactionState {
    /// SF Symbol representing this state, used in the state label and the action log.
    var systemImage: String {
        switch self {
        case .requested:
            // `questionmark.message.fill` arrived in iOS 18.1 and draws nothing on 18.0.
            if #available(iOS 18.1, *) {
                "questionmark.message.fill"
            } else {
                "questionmark.bubble.fill"
            }
        case .accepted:
            "checkmark.message.fill"
        case .confirmed:
            "hand.thumbsup.circle.fill"
        case .returned:
            "checkmark.square.fill"
        case .declined:
            "hand.thumbsdown.fill"
        case .cancelled:
            "trash"
        }
    }
}
