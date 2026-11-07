//
//  Bookshop+Link.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 07/11/2026.
//

import SwiftUI

/// What a bookshop's row under « Où trouver ce livre ? » shows.
extension Bookshop {
    var linkTitle: LocalizedStringKey {
        switch self {
        case .recyclivre: "list.where_to_find.recyclivre.title"
        case .chezMonLibraire: "list.where_to_find.chez_mon_libraire.title"
        }
    }

    var linkSubtitle: LocalizedStringKey {
        switch self {
        case .recyclivre: "list.where_to_find.recyclivre.subtitle"
        case .chezMonLibraire: "list.where_to_find.chez_mon_libraire.subtitle"
        }
    }

    var logo: ImageResource {
        switch self {
        case .recyclivre: .bookshopRecyclivre
        case .chezMonLibraire: .bookshopChezMonLibraire
        }
    }

    var linkAccessibilityID: String {
        switch self {
        case .recyclivre: "list.whereToFind.recyclivre"
        case .chezMonLibraire: "list.whereToFind.chezMonLibraire"
        }
    }
}
