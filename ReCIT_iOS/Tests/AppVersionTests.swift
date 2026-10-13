//
//  AppVersionTests.swift
//  ReCIT_iOSTests
//
//  The version the Profil's last line states, read from an Info.plist dictionary.
//

import Testing
import Foundation
@testable import ReCIT_iOS

@Suite("App version")
struct AppVersionTests {

    @Test("The marketing version and the build are read from their own keys")
    func readsBothKeys() {
        let version: AppVersion = .init(infoDictionary: [
            "CFBundleShortVersionString": "1.3.0",
            "CFBundleVersion": "10"
        ])

        #expect(version.version == "1.3.0")
        #expect(version.build == "10")
    }

    @Test("A missing key reads as empty rather than failing")
    func missingKeysAreEmpty() {
        let version: AppVersion = .init(infoDictionary: ["CFBundleVersion": "10"])

        #expect(version.version.isEmpty)
        #expect(version.build == "10")
    }

    @Test("No dictionary at all reads as two empty strings")
    func noDictionary() {
        #expect(AppVersion(infoDictionary: nil) == .init(infoDictionary: [:]))
    }

    @Test("A value of the wrong type is ignored")
    func wrongTypeIsIgnored() {
        let version: AppVersion = .init(infoDictionary: ["CFBundleShortVersionString": 13])

        #expect(version.version.isEmpty)
    }
}
