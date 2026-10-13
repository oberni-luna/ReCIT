//
//  AppVersion.swift
//  ReCIT_iOS
//
//  The version the Profil's last line states — « Ex-libris · Version 1.3.0 (10) » — read from
//  the bundle's Info.plist: `CFBundleShortVersionString` is what the App Store shows,
//  `CFBundleVersion` the build behind it, which is what a bug report needs to be traced.
//
//  Built from a plain dictionary rather than from `Bundle` so the reading can be tested without
//  one; `current` is the only place that touches the real bundle. A missing key is an empty
//  string, never a crash: the line is a courtesy, not something the screen depends on.
//

import Foundation

struct AppVersion: Equatable {
    /// The marketing version, « 1.3.0 ».
    let version: String
    /// The build number, « 10 ».
    let build: String

    init(infoDictionary: [String: Any]?) {
        version = infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        build = infoDictionary?["CFBundleVersion"] as? String ?? ""
    }

    /// The running app's version.
    static var current: AppVersion {
        .init(infoDictionary: Bundle.main.infoDictionary)
    }
}
