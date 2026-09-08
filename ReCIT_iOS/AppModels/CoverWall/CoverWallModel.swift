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
//  "No session" is now enforced rather than asserted (issue 0068): the composition root hands
//  this model a service built on `URLSession.cookieless`. The endpoint is public but sits behind
//  inventaire.io's global `cookie-session` middleware, so it answers `200` **and** an anonymous
//  `inventaire:session` — under the very name a real session uses. Absorbed into the shared jar,
//  that cookie made the launch after a sign-out open on the tabs of nobody.
//
//  The path form (`/api/items/recent-public`) and not the `?action=` alias, which inventaire.io
//  deprecated server-wide.
//
//  It also **remembers**. The paths of the last successful answer are kept in `UserDefaults` —
//  a few kilobytes of strings — and read back before any network call, so a second launch in a
//  tunnel draws the wall it drew yesterday, from Nuke's disk cache, at the first frame. The
//  painted wall is then only ever seen on a very first launch, or by someone whose server has
//  never answered. A failure never clears that list: yesterday's books beat a painted wall.
//
//  See PRD 0011 and ADR 0001 — the view reads `coverPaths`, not this method's return value.
//

import Foundation

@MainActor
@Observable
final class CoverWallModel {

    private let apiService: APIServicing
    private let defaults: UserDefaults

    /// Where the last successful answer is kept. One key, one array of strings.
    static let storageKey: String = "coverWall.recentPublicPaths"

    /// The covers to draw, in feed order. Empty until the first answer lands, which is what the
    /// painted wall is for.
    private(set) var coverPaths: [String] = []

    /// Where the images live, for the view to build its URLs against.
    var baseUrl: String { apiService.baseUrl() }

    /// Comes up on the last wall it managed to draw. `coverPaths` overrides that — a test hands
    /// it a wall to check is not lost — and an empty one falls back to what was persisted.
    init(
        apiService: APIServicing,
        defaults: UserDefaults = .standard,
        coverPaths: [String] = []
    ) {
        self.apiService = apiService
        self.defaults = defaults
        self.coverPaths = coverPaths.isEmpty
            ? Self.persistedPaths(in: defaults)
            : coverPaths
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
            defaults.set(catalog.coverPaths, forKey: Self.storageKey)
        } catch {
            // Kept on purpose: the wall that is already up stays up, and so does the list it
            // was drawn from.
        }
    }

    /// The persisted list, capped on the way in. A file on disk is not a promise: it could hold
    /// a thousand paths written by an older build, and a wall does not need them.
    private static func persistedPaths(in defaults: UserDefaults) -> [String] {
        let stored: [String] = defaults.stringArray(forKey: storageKey) ?? []

        return .init(stored.prefix(CoverWallCatalog.coverLimit))
    }
}
