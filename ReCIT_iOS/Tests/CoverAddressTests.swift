//
//  CoverAddressTests.swift
//  ReCIT_iOSTests
//
//  Which addresses a cover can be taken from — the ones `resolve` will fetch, http or https
//  with a host — and the image search that helps find one. Pure and network-free.
//
//  See PRD 0021.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@Suite("CoverAddress")
struct CoverAddressTests {

    @Test("An https or http address with a host is a cover address")
    func webAddressesAreAccepted() {
        #expect(CoverAddress.url(from: "https://exemple.org/etincelles.jpg")?.absoluteString == "https://exemple.org/etincelles.jpg")
        #expect(CoverAddress.url(from: "http://exemple.org/etincelles.jpg") != nil)
    }

    @Test("Spaces pasted around an address do not count")
    func surroundingSpacesAreTrimmed() {
        #expect(CoverAddress.url(from: "  https://exemple.org/etincelles.jpg \n")?.absoluteString == "https://exemple.org/etincelles.jpg")
    }

    /// `resolve` refuses an image that `isUrl` does not accept, and the whole entry with it.
    @Test("Anything the server could not fetch is no address")
    func otherTextIsRefused() {
        #expect(CoverAddress.url(from: "") == nil)
        #expect(CoverAddress.url(from: "exemple.org/etincelles.jpg") == nil)
        #expect(CoverAddress.url(from: "ftp://exemple.org/etincelles.jpg") == nil)
        #expect(CoverAddress.url(from: "file:///private/var/cover.jpg") == nil)
        #expect(CoverAddress.url(from: "https://") == nil)
    }

    @Test("The image search asks for the title and the ISBN together")
    func googleImagesSearch() throws {
        let url: URL = try #require(CoverAddress.googleImagesURL(title: "Étincelles écosocialistes", isbn: "9782493373052"))
        let components: URLComponents = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))

        #expect(components.host == "www.google.com")
        #expect(components.queryItems?.first(where: { $0.name == "tbm" })?.value == "isch")
        #expect(components.queryItems?.first(where: { $0.name == "q" })?.value == "Étincelles écosocialistes 9782493373052")
    }

    @Test("With no title, the image search asks for the ISBN alone")
    func googleImagesSearchWithoutTitle() throws {
        let url: URL = try #require(CoverAddress.googleImagesURL(title: " ", isbn: "9782493373052"))
        let components: URLComponents = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))

        #expect(components.queryItems?.first(where: { $0.name == "q" })?.value == "9782493373052")
    }
}
