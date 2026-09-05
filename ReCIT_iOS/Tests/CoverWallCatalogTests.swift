//
//  CoverWallCatalogTests.swift
//  ReCIT_iOSTests
//
//  What the wall keeps from a public feed, and at what size it asks for it. Both are string
//  arithmetic on data the app does not control — a feed where the same book comes back four
//  times, items with no cover art at all — so both are pinned here rather than discovered on
//  the welcome screen. See PRD 0011.
//

import Testing
import CoreGraphics
import Foundation
@testable import ReCIT_iOS

@Suite("CoverWallCatalog")
struct CoverWallCatalogTests {

    private let cover: CGSize = .init(width: 88, height: 132)

    // MARK: - Sifting the feed

    @Test func itKeepsTheCoversInFeedOrder() {
        let catalog: CoverWallCatalog = .init(imagePaths: ["/img/entities/a", "/img/entities/b"])

        #expect(catalog.coverPaths == ["/img/entities/a", "/img/entities/b"])
    }

    /// An item with no cover art contributes nothing — the wall paints that slot instead.
    @Test func itDropsItemsWithoutCoverArt() {
        let catalog: CoverWallCatalog = .init(
            imagePaths: ["/img/entities/a", nil, "", "/img/entities/b"]
        )

        #expect(catalog.coverPaths == ["/img/entities/a", "/img/entities/b"])
    }

    /// Two people owning the same book is the normal case on a public feed, and the same jacket
    /// twice on one wall reads as a bug.
    @Test func itNeverKeepsTheSameCoverTwice() {
        let catalog: CoverWallCatalog = .init(
            imagePaths: ["/img/entities/a", "/img/entities/b", "/img/entities/a"]
        )

        #expect(catalog.coverPaths == ["/img/entities/a", "/img/entities/b"])
    }

    @Test func itStopsAtItsLimit() {
        let paths: [String?] = (0..<200).map { "/img/entities/\($0)" }
        let catalog: CoverWallCatalog = .init(imagePaths: paths)

        #expect(catalog.coverPaths.count == CoverWallCatalog.coverLimit)
        #expect(catalog.coverPaths.first == "/img/entities/0")
    }

    @Test func anEmptyFeedGivesAnEmptyCatalog() {
        #expect(CoverWallCatalog(imagePaths: []).coverPaths.isEmpty)
        #expect(CoverWallCatalog(imagePaths: [nil, nil]).coverPaths.isEmpty)
    }

    @Test func aZeroLimitKeepsNothing() {
        let catalog: CoverWallCatalog = .init(imagePaths: ["/img/entities/a"], limit: 0)

        #expect(catalog.coverPaths.isEmpty)
    }

    // MARK: - Asking the server for the right size

    /// The whole point: the server resizes, and a wall of full-size jackets costs some twenty
    /// megabytes to draw a background.
    @Test func itAsksForACoverAtTheSizeItIsDrawn() {
        let sized: String = CoverWallCatalog.sizedPath(
            "/img/entities/abc123",
            coverSize: cover,
            scale: 2
        )

        #expect(sized == "/img/entities/176x264/abc123")
    }

    @Test func itFollowsTheScreenScale() {
        let atThree: String = CoverWallCatalog.sizedPath(
            "/img/entities/abc123",
            coverSize: cover,
            scale: 3
        )

        #expect(atThree == "/img/entities/264x396/abc123")
    }

    /// A path that already carries a size, or that is not one of inventaire.io's image paths,
    /// is left exactly as it is: the size segment is that server's convention and means nothing
    /// elsewhere.
    @Test(arguments: [
        "/img/entities/176x264/abc123",
        "https://commons.wikimedia.org/wiki/Special:FilePath/Some%20Cover.jpg",
        "abc123",
        "",
    ]) func itLeavesEveryOtherShapeAlone(path: String) {
        #expect(CoverWallCatalog.sizedPath(path, coverSize: cover, scale: 2) == path)
    }

    @Test func aCoverOfNoSizeIsAskedForUnsized() {
        let sized: String = CoverWallCatalog.sizedPath(
            "/img/entities/abc123",
            coverSize: .zero,
            scale: 2
        )

        #expect(sized == "/img/entities/abc123")
    }

    @Test func itBuildsAnAbsoluteUrlOnTheServerItWasGiven() {
        let url: URL? = CoverWallCatalog.url(
            baseUrl: "https://inventaire.io",
            path: "/img/entities/abc123",
            coverSize: cover,
            scale: 2
        )

        #expect(url?.absoluteString == "https://inventaire.io/img/entities/176x264/abc123")
    }

    /// An already-absolute cover — a Wikimedia one, which the app meets elsewhere — is not
    /// prefixed with the inventaire.io host.
    @Test func itDoesNotPrefixAnAbsoluteCover() {
        let url: URL? = CoverWallCatalog.url(
            baseUrl: "https://inventaire.io",
            path: "https://example.org/cover.jpg",
            coverSize: cover,
            scale: 2
        )

        #expect(url?.absoluteString == "https://example.org/cover.jpg")
    }
}
