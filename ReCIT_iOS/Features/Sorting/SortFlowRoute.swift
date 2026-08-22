//
//  SortFlowRoute.swift
//  ReCIT_iOS
//
//  Where the sorting flow can push, and where it starts. Two small types rather than cases of
//  `NavigationDestination`, because nothing outside this modal can reach either of them — and
//  an app-wide navigation enum that grows a case per screen inside every flow is an enum every
//  tab has to know about. See PRD 0009.
//

import Foundation

/// A screen the flow pushes onto its own stack.
enum SortFlowRoute: Hashable {
    /// The sorting surface. Pushed from the bilan; the root when the flow starts at `.sorting`.
    case sorting
}

/// Where the flow opens, which is the whole difference between its two entry points.
enum SortFlowStart: Hashable {
    /// Camera, then the bilan, then the surface. Onboarding, and the scan buttons.
    case scanning
    /// The surface, as the root. The home's and settings' route, for a user who came to file
    /// what they already have.
    case sorting
}
