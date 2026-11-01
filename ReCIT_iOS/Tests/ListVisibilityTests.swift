//
//  ListVisibilityTests.swift
//  ReCIT_iOSTests
//
//  The five answers of the list form's « Visible par », read from inventaire.io's visibility
//  keys and written back as them. Pure and network-free.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@Suite
struct ListVisibilityTests {
    @Test
    func keysAreReadAsOneOfTheFiveAnswers() {
        #expect(ListVisibility(attributes: []) == .private)
        #expect(ListVisibility(attributes: [.friends]) == .friends)
        #expect(ListVisibility(attributes: [.groups]) == .groups)
        #expect(ListVisibility(attributes: [.groups, .friends]) == .friendsAndGroups)
        #expect(ListVisibility(attributes: [.friends, .public, .groups]) == .public)
    }

    @Test
    func eachAnswerIsWrittenAsTheKeysItIsReadFrom() {
        for option in ListVisibility.allCases {
            #expect(ListVisibility(attributes: option.attributes) == option)
        }
    }

    @Test
    func onlyMeIsWrittenAsNoKey() {
        #expect(ListVisibility.private.attributes.isEmpty)
        #expect(ListVisibility.friendsAndGroups.attributes == [.friends, .groups])
    }
}
