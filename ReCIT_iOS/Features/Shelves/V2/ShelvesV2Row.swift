//
//  ShelvesV2Row.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 06/11/2026.
//
//  One étagère in « Étagères (v2) »: its name, how many books it holds, and a chevron.
//

import SwiftData
import SwiftUI

struct ShelvesV2Row: View {
    let shelf: Shelf

    init(_ shelf: Shelf) {
        self.shelf = shelf
    }

    var body: some View {
        HStack(spacing: .small) {
            VStack(alignment: .leading, spacing: .xxSmall) {
                Text(shelf.name)
                    .textStyle(.content400Bold)
                    .foregroundStyle(.foregroundDefault)

                Text("shelves.v2.count \(shelf.items.count)")
                    .textStyle(.footnote200)
                    .foregroundStyle(.foregroundSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .textStyle(.footnote200)
                .foregroundStyle(.foregroundSecondary)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, .medium)
        .padding(.vertical, .sMedium)
        .contentShape(.rect)
    }
}

#Preview(traits: .modifier(ShelfPreviewStore())) {
    @Previewable @Query var shelves: [Shelf]
    if let shelf = shelves.first {
        ShelvesV2Row(shelf)
    }
}
