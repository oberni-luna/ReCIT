//
//  TransactionRole.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 04/08/2026.
//

import Foundation

/// Which side of a transaction a given user sits on.
enum TransactionRole: Equatable, Hashable {
    case requester
    case owner
}
