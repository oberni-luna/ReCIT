//
//  ShelfModel+InFlightWrites.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 16/11/2026.
//

import Foundation
import SwiftData

extension ShelfModel {
    /// Runs an awaiting membership write with the étagère and its books in `InFlightWrites`,
    /// so no sync lands on them before the server has answered.
    ///
    /// The auto-sort and sorting applies (PRD 0006, PRD 0008) issue one such write per étagère
    /// in a row, while a single-book write from a menu may settle in the middle of the run.
    /// `InFlightWrites` counts its entries, so the one settling does not free the étagère or
    /// the books the run still holds.
    func whileInFlight(
        _ shelf: Shelf,
        _ items: [InventoryItem],
        _ write: () async throws -> Void
    ) async rethrows {
        let written: [PersistentIdentifier] = [shelf.persistentModelID] + items.map(\.persistentModelID)
        inFlightWrites.begin(written)
        defer { inFlightWrites.end(written) }
        try await write()
    }
}
