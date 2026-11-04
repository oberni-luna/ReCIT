//
//  BioLinksTests.swift
//  ReCIT_iOSTests
//

import Foundation
import Testing
@testable import ReCIT_iOS

@Suite("A bio's links")
struct BioLinksTests {
    @Test("An address without a scheme becomes a link, the text around it stays plain")
    func bareAddress() {
        let bio: AttributedString = UserPresentationTab.linked("Nos découvertes sur www.utopitheque.com et ailleurs")
        let links: [URL] = bio.runs.compactMap(\.link)

        #expect(links.count == 1)
        #expect(links.first?.host() == "www.utopitheque.com")
        #expect(String(bio.characters) == "Nos découvertes sur www.utopitheque.com et ailleurs")
    }

    @Test("A bio with no address has no link")
    func noAddress() {
        let bio: AttributedString = UserPresentationTab.linked("Lectrice de science-fiction.")

        #expect(bio.runs.allSatisfy { $0.link == nil })
    }
}
