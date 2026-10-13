//
//  NetworkNodeAction+Title.swift
//  ReCIT_iOS
//
//  The name VoiceOver gives each action on a node of the Réseau graph: the words of the sheet's
//  own buttons (PRD 0019, Q44).
//

import SwiftUI

extension NetworkNodeAction {
    var title: LocalizedStringKey {
        switch self {
        case .openGroup: "network.graph.open_group"
        case .viewProfile: "network.graph.view_profile"
        case .accept: "network.invitation.accept"
        case .refuse: "network.invitation.refuse"
        }
    }
}
