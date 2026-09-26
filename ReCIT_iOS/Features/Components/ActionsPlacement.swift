//
//  ActionsPlacement.swift
//  ReCIT_iOS
//
//  Where an entity's actions menu is carried: the "…" of a detail screen's navigation bar,
//  or the long press of a row showing that entity. See `bookActions` and `workActions`.
//

enum ActionsPlacement {
    /// The "…" button of the navigation bar.
    case toolbar
    /// A long press on the view.
    case contextMenu
}
