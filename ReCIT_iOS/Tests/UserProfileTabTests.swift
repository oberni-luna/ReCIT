//
//  UserProfileTabTests.swift
//  ReCIT_iOSTests
//
//  Created by Olivier Berni on 06/11/2026.
//

import Testing
@testable import ReCIT_iOS

@Suite
struct UserProfileTabTests {
    @Test
    func `a friend's profile has Échanges between Listes and Présentation`() {
        #expect(UserProfileTab.pages(isMine: false) == [.inventory, .lists, .transactions, .presentation])
    }

    @Test
    func `my own profile has no Échanges`() {
        #expect(UserProfileTab.pages(isMine: true) == [.inventory, .lists, .presentation])
    }
}
