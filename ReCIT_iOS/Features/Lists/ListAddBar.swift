//
//  ListAddBar.swift
//  ReCIT_iOS
//
//  What a list's screen pins at its foot in place of the tab bar: « Ajouter un livre », then
//  « Scanner » and « Rechercher » side by side. A list of authors has nothing to scan, so it says
//  « Ajouter un·e auteur·ice » over « Rechercher » alone.
//
//  Pinned through `formActionBar`, the bar the long forms use, so it sits on the same surface and
//  follows the same soft edge.
//
//  See PRD 0029.
//

import SwiftUI

struct ListAddBar: View {
    let listType: EntityListType
    let onScan: () -> Void
    let onSearch: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: .small) {
            Text(listType == .author ? "list.detail.add.author" : "list.detail.add.work")
                .textStyle(.caption200)
                .foregroundStyle(.foregroundSecondary)

            HStack(spacing: .sMedium) {
                if listType == .work {
                    Button(action: onScan) {
                        Label("list.detail.add.scan", systemImage: "barcode.viewfinder")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.pill(.prominent))
                }

                Button(action: onSearch) {
                    Label("list.detail.add.search", systemImage: "magnifyingglass")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.pill(.prominent))
            }
        }
    }
}
