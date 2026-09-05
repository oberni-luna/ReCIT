//
//  CoverWallModel.swift
//  ReCIT_iOS
//
//  Fetches the covers the welcome screen's wall is built from: one public, unauthenticated call
//  to `GET /api/items/recent-public`, which answers the last books published on inventaire.io
//  with their cover path already in the snapshot. No entity call, no session, no user.
//
//  It is the one model in the app that runs **before** anyone is signed in, which sets its
//  manners: it never throws at the screen, and a failure leaves the wall exactly as it was.
//  A welcome screen that emptied itself because a server hiccuped would be worse than a welcome
//  screen that shows yesterday's books.
//
//  The path form (`/api/items/recent-public`) and not the `?action=` alias, which inventaire.io
//  deprecated server-wide.
//
//  See PRD 0011 and ADR 0001 — the view reads `coverPaths`, not this method's return value.
//

import Foundation

@MainActor
@Observable
final class CoverWallModel {

    private let apiService: APIServicing

    /// The covers to draw, in feed order. Empty until the first answer lands, which is what the
    /// painted wall is for.
    private(set) var coverPaths: [String] = []

    /// Where the images live, for the view to build its URLs against.
    var baseUrl: String { apiService.baseUrl() }

    /// `coverPaths` seeds the wall before any network call. Issue 0071 hands it the list it
    /// persisted from the last successful answer; a test hands it a wall to check is not lost.
    init(apiService: APIServicing, coverPaths: [String] = []) {
        self.apiService = apiService
        self.coverPaths = coverPaths
    }

    /// Asks for the latest public books and keeps their covers. Silent by design: no error
    /// reporter, no thrown error, no snackbar. Nobody signed in yet, nothing the reader could
    /// do about it, and the screen already has a wall.
    func refresh() async {
        do {
            let response: RecentPublicItemsDTO? = try await apiService.fetchData(
                fromEndpoint: "/api/items/recent-public?limit=\(CoverWallCatalog.coverLimit)"
            )

            guard let items = response?.items, items.isEmpty == false else { return }

            let catalog: CoverWallCatalog = .init(
                imagePaths: items.map { $0.snapshot?.`entity:image` }
            )

            guard catalog.coverPaths.isEmpty == false else { return }

            coverPaths = catalog.coverPaths
        } catch {
            // Kept on purpose: the wall that is already up stays up.
        }
    }
}
