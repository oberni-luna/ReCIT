//
//  DeepLink.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 15/11/2026.
//

import Foundation

/// An Ex-libris link, `https://link.exlibris.lunabee.ovh/entity/<uri>`, read off the URL the system
/// hands the app when it opens one. The path is inventaire.io's own, so that the link's server only
/// has to send the same path to inventaire.io when the app is not installed (`scripts/deeplinks/`).
enum DeepLink: Equatable, Sendable {
    /// A book, a work or an author, by its inventaire.io uri: `isbn:…`, `wd:Q…`, `inv:…`.
    case entity(uri: String)

    /// The domain the links live on. The app claims it in its entitlements, and the server sends
    /// the two files that tie it to the iOS and Android apps.
    static let host: String = "link.exlibris.lunabee.ovh"

    /// The same page on inventaire.io: where the link goes when the app cannot open it.
    var webURL: URL? {
        switch self {
        case let .entity(uri):
            URL(string: "https://inventaire.io/entity/\(uri)")
        }
    }

    /// `nil` for any URL that is not one of the app's links, or one of a shape it does not open.
    init?(url: URL) {
        guard url.scheme == "https", url.host() == Self.host else { return nil }

        let components: [String] = url.pathComponents.filter { $0 != "/" }
        guard components.count == 2, components[0] == "entity" else { return nil }

        let uri: String = components[1]
        guard uri.wholeMatch(of: /(?:isbn|wd|inv):[A-Za-z0-9-]+/) != nil else { return nil }

        self = .entity(uri: uri)
    }
}
