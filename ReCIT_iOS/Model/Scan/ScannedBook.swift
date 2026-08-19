//
//  ScannedBook.swift
//  ReCIT_iOS
//
//  The batch scanner's view of a book, flattened out of the resolved edition so the scan
//  state machine — and its tests — never touch SwiftData, SwiftUI or the camera package.
//
//  `uri` is the *canonical* entity uri the server answered with, never the `isbn:` uri that
//  was asked for: inventaire keys an edition by its own id, and that is the uri an inventory
//  item has to be created from. See PRD 0005.
//

import Foundation

struct ScannedBook: Equatable {
    /// Canonical uri of the resolved edition (e.g. `inv:…`), never the requested `isbn:…`.
    let uri: String
    let title: String
    let authors: [String]
    let coverImageUrl: String?
    /// The barcode this book was resolved from, so a lookup that lands after the user has
    /// moved on can be told apart from the one the row is waiting for.
    let code: String

    var authorsLine: String {
        authors.joined(separator: ", ")
    }

    /// Plausible strings for the looking-up row. Redaction needs *content* to redact — an
    /// empty string greys out to nothing — so these exist purely to be covered up, at the
    /// same line count and roughly the same length as the real thing.
    static let placeholder: ScannedBook = .init(
        uri: "",
        title: "Le livre que vous scannez",
        authors: ["Prénom Nom"],
        coverImageUrl: nil,
        code: ""
    )
}
