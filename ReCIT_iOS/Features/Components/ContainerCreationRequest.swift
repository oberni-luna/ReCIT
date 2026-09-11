//
//  ContainerCreationRequest.swift
//  ReCIT_iOS
//
//  What a "…" menu asks for when the user picks its last line: a container that does not
//  exist yet, and what is to be filed into it once it does.
//
//  The menus never present anything themselves — a `.sheet` placed inside a `Menu`'s content
//  does not present reliably. They write this value into a binding the screen owns, and the
//  screen's `containerCreationSheet(_:)` mounts the right form. See PRD 0014.
//
//  Free of SwiftUI and SwiftData on purpose, like `MembershipMenuEntry`: it names its subject
//  by identifier and nothing more, so whoever mounts the sheet resolves the object — it may
//  have been deleted while the sheet was open.
//

import Foundation

enum ContainerCreationRequest: Identifiable, Equatable, Sendable {

    /// File a work — named by its uri — into a liste that does not exist yet.
    case list(workUri: String)

    /// File a copy — named by its inventory item id — onto an étagère that does not exist yet.
    case shelf(itemID: String)

    /// Identity of the demand, which is what `.sheet(item:)` presents on.
    var id: String {
        switch self {
        case .list(let workUri): "list:\(workUri)"
        case .shelf(let itemID): "shelf:\(itemID)"
        }
    }
}
