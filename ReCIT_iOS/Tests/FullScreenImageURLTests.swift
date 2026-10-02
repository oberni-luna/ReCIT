//
//  FullScreenImageURLTests.swift
//  ReCIT_iOSTests
//

import Foundation
import Testing
@testable import ReCIT_iOS

@Suite("Full-screen image url")
struct FullScreenImageURLTests {

    @Test("A Wikimedia file asked at 512 or 1024 is asked at full-screen width")
    func wikimediaWidthIsRaised() throws {
        let url: URL = try #require(URL(string: "https://commons.wikimedia.org/wiki/Special:FilePath/Victor%20Hugo.jpg?width=1024"))

        let resolved: URL = FullScreenImageURL.resolve(url)

        let items: [URLQueryItem] = URLComponents(url: resolved, resolvingAgainstBaseURL: false)?.queryItems ?? []
        #expect(items.filter { $0.name == "width" }.map(\.value) == ["2048"])
        #expect(resolved.path() == url.path())
    }

    @Test("A Wikimedia file asked at no width is given one")
    func wikimediaWidthIsAdded() throws {
        let url: URL = try #require(URL(string: "https://commons.wikimedia.org/wiki/Special:FilePath/Cover.jpg"))

        #expect(FullScreenImageURL.resolve(url).absoluteString.hasSuffix("?width=2048"))
    }

    @Test("An inventaire.io image already names its original, and is left alone")
    func inventaireImageIsUnchanged() throws {
        let url: URL = try #require(URL(string: "https://inventaire.io/img/entities/63b88ac1290ce52588b4a39d59f3679853394c49"))

        #expect(FullScreenImageURL.resolve(url) == url)
    }
}
