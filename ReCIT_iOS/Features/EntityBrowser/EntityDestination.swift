//
//  EntityDestination.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 23/01/2026.
//

import Foundation
import SwiftUI

enum EntityDestination: Hashable, Identifiable {
    case author(uri: String)
    case work(uri: String)
    case edition(uri: String)

    var id: String {
        switch self {
        case .author(let uri):
            return "author:\(uri)"
        case .work(let uri):
            return "work:\(uri)"
        case .edition(let uri):
            return "edition:\(uri)"
        }
    }

    @ViewBuilder
    func viewForDestination(_ path: Binding<NavigationPath>) -> some View {
        switch self {
        case .author(let uri):
            AuthorDetailView(authorUri: uri, path: path)
        case .work(let uri):
            WorkDetailView(workUri: uri, path: path)
        case .edition(let uri):
            EditionDetailView(editionUri: uri, path: path)
        }
    }

    static func destinationForSearchResult(_ result: SearchResult) -> EntityDestination? {
        switch result.type {
        case .works:
            return .work(uri: result.uri)
        case .humans:
            return .author(uri: result.uri)
        default:
            return nil
        }
    }
}
