//
//  SharingVisibilityTests.swift
//  ReCIT_iOSTests
//
//  Created by Olivier Berni on 16/11/2026.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@Suite
@MainActor
struct SharingVisibilityTests {
    @Test
    func `a list of mine without a visibility key is not shareable`() {
        #expect(EntityList.mock(visibility: []).isShareable(isMine: true) == false)
        #expect(EntityList.mock(visibility: [.friends]).isShareable(isMine: true))
        #expect(EntityList.mock(visibility: [.groups]).isShareable(isMine: true))
        #expect(EntityList.mock(visibility: [.public]).isShareable(isMine: true))
    }

    @Test
    func `a friend's list without a visibility key is still shareable`() {
        #expect(EntityList.mock(visibility: []).isShareable(isMine: false))
    }

    @Test
    func `an étagère of mine without a visibility key is not shareable`() {
        #expect(Shelf.mock(visibility: []).isShareable(isMine: true) == false)
        #expect(Shelf.mock(visibility: ["friends"]).isShareable(isMine: true))
        #expect(Shelf.mock(visibility: ["groups"]).isShareable(isMine: true))
        #expect(Shelf.mock(visibility: ["group:2b8c1752cc1195dafc3a8910f80822df"]).isShareable(isMine: true))
        #expect(Shelf.mock(visibility: ["public"]).isShareable(isMine: true))
    }

    @Test
    func `a friend's étagère without a visibility key is still shareable`() {
        #expect(Shelf.mock(visibility: []).isShareable(isMine: false))
    }
}
