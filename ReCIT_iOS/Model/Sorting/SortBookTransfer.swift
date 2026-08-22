//
//  SortBookTransfer.swift
//  ReCIT_iOS
//
//  What travels under the finger when a book is dragged across the sorting surface: an
//  item's server `_id`, and nothing else.
//
//  **Under an app-private content type**, not `String`. A plain string payload is offered to
//  every app that accepts text, so a book dragged a little too far would be dropped into
//  Notes or Messages as the characters « inv:… », which is both meaningless and alarming.
//  With a type only this app declares, no other app will take the drop.
//
//  **The origin does not travel.** The projection knows where every book sits, and the
//  session resolves the origin at the moment of the drop — so a payload cannot name a
//  section the book has since left, which is exactly the class of bug a carried origin
//  produced in the first attempt at this gesture (PRD 0008, superseded by PRD 0009).
//
//  Note for whoever adds a second draggable thing: the identifier is exported without a
//  matching `UTExportedTypeDeclarations` entry, because the target generates its
//  `Info.plist`. Within the app that is enough — the type is unknown to other apps, which is
//  the property being bought. Declare it properly the day a drop has to cross an app
//  boundary on purpose.
//

import CoreTransferable
import UniformTypeIdentifiers

struct SortBookTransfer: Codable, Transferable, Equatable, Sendable {

    /// The `InventoryItem._id` of the book being carried.
    let bookId: String

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .sortBook)
    }
}

extension UTType {

    /// The sorting surface's own payload type. Reverse-DNS, so it cannot collide with
    /// anything, and conforming to `data` rather than `text` so nothing offers to paste it
    /// somewhere as characters.
    static let sortBook: UTType = .init(exportedAs: "com.lunabee.recit.sort-book", conformingTo: .data)
}
