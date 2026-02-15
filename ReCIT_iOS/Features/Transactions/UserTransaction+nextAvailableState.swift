//
//  UserTransaction+nextAvailableState.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 14/02/2026.
//

import Foundation

extension UserTransaction {

    func nextAvailableState(for user: User) -> [TransactionState]? {
        var amIRequester: Bool {
            self.requester._id == user._id
        }

        if self._id.isEmpty {
            return [TransactionState.requested]
        }
        switch self.state {
        case .requested:
            return amIRequester ? nil : [.accepted, .declined]
        case .accepted:
            return amIRequester ? [.confirmed] : nil
        case .confirmed:
            return amIRequester ? nil : [.returned]
        case .returned:
            return nil
        case .declined:
            return nil
        }
    }

}
