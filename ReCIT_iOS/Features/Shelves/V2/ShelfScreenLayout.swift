//
//  ShelfScreenLayout.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 06/11/2026.
//
//  Which screen an étagère opens on: the first one, a plain list of its books
//  (`ShelfDetailView`), or the v2, « Livres » and « Présentation » in two tabs
//  (`ShelfDetailV2View`). Carried by `NavigationDestination.shelf` while the two are tried side
//  by side; it goes with the one that loses.
//

import SwiftUI

enum ShelfScreenLayout: Hashable {
    case list
    case tabs

    @ViewBuilder
    func screen(
        shelfId: String,
        path: Binding<NavigationPath>
    ) -> some View {
        switch self {
        case .list:
            ShelfDetailView(shelfId: shelfId, path: path)
        case .tabs:
            ShelfDetailV2View(shelfId: shelfId, path: path)
        }
    }
}
