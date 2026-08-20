//
//  EntityDestination.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 23/01/2026.
//

import Foundation
import SwiftUI
import SwiftData

enum NavigationDestination: Equatable, Hashable, Identifiable {
    case author(uri: String)
    case work(uri: String)
    case book(anchor: BookAnchor)
    case user(user: User)
    case transaction(transaction: UserTransaction)
    case allTransactions
    case entityList(id: String)
    case shelf(id: String)
    /// The AI shelving proposal (PRD 0006). Carries nothing: the plan lives on
    /// `AutoSortModel`, so navigating back and forth cannot re-run it by accident.
    case autoSort
    /// The manual sorting surface (PRD 0008). Carries nothing: the session and its
    /// frozen snapshot belong to the screen, so pushing it twice cannot half-restore
    /// a sorting session.
    case manualSort

    var id: String {
        switch self {
        case .author(let uri):
            return "author:\(uri)"
        case .work(let uri):
            return "work:\(uri)"
        case .book(let anchor):
            return "book:\(anchor.stableId)"
        case .user(let user):
            return "user:\(user._id)"
        case .transaction(let transaction):
            return "transaction:\(transaction._id)"
        case .allTransactions:
            return "allTransactions"
        case .entityList(let id):
            return "entityList:\(id)"
        case .shelf(let id):
            return "shelf:\(id)"
        case .autoSort:
            return "autoSort"
        case .manualSort:
            return "manualSort"
        }
    }

    // Equatable / Hashable are defined on `id` rather than synthesized. Several
    // cases carry SwiftData `@Model` payloads whose synthesized conformance does
    // not compose cleanly into this enum under strict concurrency. `id` is the
    // navigation identity, so this is also the correct notion of equality.
    static func == (lhs: NavigationDestination, rhs: NavigationDestination) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func destinationForSearchResult(_ result: SearchResult) -> NavigationDestination? {
        switch result.type {
        case .works:
            return .work(uri: result.uri)
        case .humans:
            return .author(uri: result.uri)
        case .inventoryItem:
            if let item = result.localItem {
                return .book(anchor: .item(item))
            } else {
                return nil
            }
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
          WorkEditionGatewayView(workUri: uri, path: path)
      case .book(let anchor):
          BookDetailView(anchor: anchor, path: path)
      case .user(let user):
          UserDetailView(user:user, path: path)
      case .transaction(let transaction):
          TransactionDetailView(transaction: transaction, path: path)
      case .allTransactions:
          AllTransactionsView()
      case .entityList(let id):
          EntityListDetail(listId: id, path: path)
      case .shelf(let id):
          ShelfDetailView(shelfId: id, path: path)
      case .autoSort:
          AutoSortPlanView(path: path)
      case .manualSort:
          ManualSortView(path: path)
      }
    }
}
