//
//  NetworkSheetAnswer.swift
//  ReCIT_iOS
//
//  The two answers the sheet of the Réseau graph gives to what waits on me — an invitation to a
//  group, a reader asking to be my friend (PRD 0019, Q26, issue 0108). The sheet only says which
//  was touched; `NetworkAllView` makes the gesture, with the same optimistic writes as the rows
//  of the lists (ADR 0001).
//

import Foundation

enum NetworkSheetAnswer: Hashable, Sendable {
    case accept
    case refuse

    /// The membership gesture that answers an invitation to a group this way.
    var groupAction: GroupAction {
        switch self {
        case .accept:
            .accept
        case .refuse:
            .decline
        }
    }
}
