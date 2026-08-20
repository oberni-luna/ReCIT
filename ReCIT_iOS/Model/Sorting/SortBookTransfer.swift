//
//  SortBookTransfer.swift
//  ReCIT_iOS
//
//  What travels between a finger picking a book up and a section receiving it: the
//  book's identity, and the section it came from.
//
//  **The origin travels with the book** because a move records where it came from as
//  well as where it goes (`SortChange.moveBook`). Deriving the origin at the drop —
//  by asking the projection which section currently holds the book — would make the
//  stack a function of the projection, which is the coupling the stack exists to
//  avoid; it would also be wrong the moment two drags overlap.
//
//  Typed rather than a bare string: `List`'s built-in move reorders inside one section
//  and never crosses sections, so the gesture is a real drag with a real payload, and
//  the drop destination is a `SortSection` (PRD 0008). A private content type keeps
//  the sections from lighting up under a photo or a URL dragged in from another app.
//
//  Pure by design — no store, no SwiftUI. See PRD 0008.
//

import CoreTransferable
import UniformTypeIdentifiers

struct SortBookTransfer: Codable, Equatable, Sendable, Transferable {

    /// The item's server `_id` — what `AutoSortBook.id` and every change carry.
    let bookId: String

    /// The section the book was dragged out of.
    let origin: SortSection.ID

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .recitSortBook)
    }
}

extension UTType {

    /// The app's own drag payload. Not declared in an `Info.plist` — the target
    /// generates one from build settings and has no file to declare it in — which is
    /// only about other apps understanding the type. This one never leaves the
    /// process: it is registered by the row that starts the drag and matched by the
    /// section that receives it, both inside RECITs.
    static let recitSortBook: UTType = .init(exportedAs: "com.recit.manual-sort.book")
}
