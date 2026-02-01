//
//  EntityDestination.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 23/01/2026.
//

import Foundation
import SwiftUI

enum NavigationDestination: Hashable, Identifiable {
    case author(uri: String)
    case work(uri: String)
    case edition(uri: String)
    case user(user: User)
    case item(item: InventoryItem)

    var id: String {
        switch self {
        case .author(let uri):
            return "author:\(uri)"
        case .work(let uri):
            return "work:\(uri)"
        case .edition(let uri):
            return "edition:\(uri)"
        case .user(let user):
            return "user:\(user._id)"
        case .item(let item):
            return "item:\(item._id)"
        }
    }

    static func destinationForSearchResult(_ result: SearchResult) -> NavigationDestination? {
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
extension NavigationDestination {
    @ViewBuilder
    func viewForDestination(_ path: Binding<NavigationPath>) -> some View {
      switch self {
      case .author(let uri):
          AuthorDetailView(authorUri: uri, path: path)
      case .work(let uri):
          WorkDetailView(workUri: uri, path: path)
      case .edition(let uri):
          EditionDetailView(editionUri: uri, path: path)
      case .user(let user):
          UserDetailView(user:user, path: path)
      case .item(let item):
          InventoryItemDetailView(item: item, path: path)
      }
    }
}
