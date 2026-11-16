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
    func `a list without a visibility key is its creator's alone`() {
        #expect(EntityList.mock(visibility: []).isVisibleToCreatorAlone)
        #expect(EntityList.mock(visibility: [.friends]).isVisibleToCreatorAlone == false)
        #expect(EntityList.mock(visibility: [.groups]).isVisibleToCreatorAlone == false)
        #expect(EntityList.mock(visibility: [.public]).isVisibleToCreatorAlone == false)
    }

    @Test
    func `an étagère without a visibility key is its owner's alone`() {
        #expect(Shelf.mock(visibility: []).isVisibleToOwnerAlone)
        #expect(Shelf.mock(visibility: ["friends"]).isVisibleToOwnerAlone == false)
        #expect(Shelf.mock(visibility: ["groups"]).isVisibleToOwnerAlone == false)
        #expect(Shelf.mock(visibility: ["group:2b8c1752cc1195dafc3a8910f80822df"]).isVisibleToOwnerAlone == false)
        #expect(Shelf.mock(visibility: ["public"]).isVisibleToOwnerAlone == false)
    }
}
