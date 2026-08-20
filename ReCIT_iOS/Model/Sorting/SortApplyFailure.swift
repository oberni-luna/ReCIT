//
//  SortApplyFailure.swift
//  ReCIT_iOS
//
//  Why an apply stopped, when the reason is the app's own state rather than the
//  network's.
//
//  Spelled out rather than folded into `NetworkError` because the user's recovery
//  differs: a network failure is worth pressing the button again straight away, a
//  library that moved under the run has to be reopened so the snapshot is taken
//  afresh. Both reach the user through the shared `AppErrorReporter` — the per-étagère
//  account is the report on the screen, not a snackbar per failure (PRD 0008).
//

import Foundation

enum SortApplyFailure: LocalizedError {

    /// The étagère the plan was going to write to is no longer in the store.
    case shelfNoLongerExists(shelfName: String)

    /// None of the books the plan was going to file are in the inventory any more.
    case booksNoLongerInInventory(shelfName: String)

    var errorDescription: String? {
        switch self {
        case .shelfNoLongerExists(let shelfName):
            String(localized: "manual_sort.error.shelf_missing \(shelfName)")
        case .booksNoLongerInInventory(let shelfName):
            String(localized: "manual_sort.error.books_missing \(shelfName)")
        }
    }
}
