//
//  MyInventoryCell.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 07/11/2025.
//

import SwiftUI

struct InventoryCell: View {
    let item: InventoryItem
    let filterParameter: InventoryItem.FilterParameter
    /// Set where the row is not a `List` cell — « Tous les livres », under the étagères. A cell
    /// lends its long-press preview its own margins, ground and rounded corners; a bare row
    /// lifted only its text, flush against the cover, on a ground the page shares. Standing
    /// alone, the row pads itself and carries that card before the menu is attached.
    var standsAlone: Bool = false

    var body: some View {
        // `isStillInTheStore` first, and it is not decoration: this cell is the one the crash of
        // issue 0065 came out of. The book screen deletes the copy and stays put, this row is
        // still on screen behind it, and the deletion invalidates its body — which then read
        // `item.transaction` off a model with no row left and trapped. See
        // `PersistentModel+StillInTheStore`.
        if item.isStillInTheStore, let edition = item.edition {
            HStack(alignment: .top, spacing: .sMedium) {
                CellThumbnail(imageUrl: edition.image, cornerRadius: .minimal, size: .medium, shape: .portrait)

                VStack(alignment: .leading, spacing: .xSmall) {
                    Group {
                        Text(edition.title)
                            .textStyle(.content400Bold)

                        if let subtitle = edition.subtitle {
                            Text(subtitle)
                                .textStyle(.content300)
                        }

                        let authorNames: [String] = edition.displayedAuthorNames
                        if authorNames.isEmpty == false {
                            Text(AuthorNamesSummary(authorNames).text)
                                .textStyle(.footnote200)
                        }

                    }
                    .foregroundStyle(.foregroundDefault)

                    HStack(alignment: .firstTextBaseline, spacing: .small) {
                        item.transaction.label
                            .labelStyle(.tag)

                        if filterParameter == .othersInventory, let owner = item.owner {
                            Text(.init(String(localized: "inventory.owned_by \(owner.username)")))
                                .textStyle(.footnote200Bold)
                                .foregroundStyle(.foregroundDefault)
                        }
                    }
                }
            }
            .modifier(StandAloneCard(isOn: standsAlone))
            // The book screen's "…" menu, on a long press — every list of books carries it
            // through this cell. The edition is read here, under the store guard above.
            .bookActions(
                edition: edition,
                placement: .contextMenu
            )
        }
    }
}
