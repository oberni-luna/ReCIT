//
//  DeepLink.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 15/11/2026.
//

import Foundation

/// An Ex-libris link, `https://link.exlibris.lunabee.ovh/<path>`, read off the URL the system hands
/// the app when it opens one. The paths are inventaire.io's own, so that the link's server only has
/// to send the same path to inventaire.io when the app is not installed (`scripts/deeplinks/`).
///
/// A path segment is decoded before it is read, and ends up in a query string: a segment that is
/// not a whole match of what inventaire.io allows makes the URL no link at all.
enum DeepLink: Equatable, Sendable {
    /// A book, a work or an author, by its inventaire.io uri: `isbn:…`, `wd:…`, `inv:…`.
    case entity(uri: String)
    /// A reader, by their username, in whatever case it was typed.
    case user(username: String)
    /// A group, by its slug.
    case group(slug: String)
    /// A list, opened on its first element, or on the element `elementId` names when it has one.
    case list(id: String, elementId: String?)

    /// The domain the links live on. The app claims it in its entitlements, and the server sends
    /// the two files that tie it to the iOS and Android apps.
    static let host: String = "link.exlibris.lunabee.ovh"

    /// The same page on inventaire.io: where the link goes when the app cannot open it.
    var webURL: URL? {
        switch self {
        case let .entity(uri):
            URL(string: "https://inventaire.io/entity/\(uri)")
        case let .user(username):
            URL(string: "https://inventaire.io/users/\(username)")
        case let .group(slug):
            URL(string: "https://inventaire.io/groups/\(slug)")
        case let .list(id, nil):
            URL(string: "https://inventaire.io/lists/\(id)")
        case let .list(id, elementId?):
            URL(string: "https://inventaire.io/lists/\(id)/element/\(elementId)")
        }
    }

    /// `nil` for any URL that is not one of the app's links, or one of a shape it does not open.
    init?(url: URL) {
        guard url.scheme == "https", url.host() == Self.host else { return nil }

        let components: [String] = url.pathComponents.filter { $0 != "/" }
        guard let link = Self.list(at: components) ?? Self.page(at: components) else { return nil }
        self = link
    }
}

private extension DeepLink {
    /// inventaire.io's rule, `Username` in `server/lib/regex.ts`: two to twenty letters, digits or
    /// `_`, in any script, counted by code point as JavaScript counts them.
    static var username: Regex<Substring> {
        /[\p{Letter}\p{Number}_]{2,20}/.matchingSemantics(.unicodeScalar)
    }

    /// What inventaire.io's `slugify` leaves of a group's name — letters in any script and `-` —
    /// then the `.1`, `.2`… it appends when the slug is taken. Digits as well, as in the uris.
    static var slug: Regex<Substring> {
        /[\p{Letter}0-9-]+(?:\.[0-9]+)?/.matchingSemantics(.unicodeScalar)
    }

    /// `lists/<id>`, or `lists/<id>/element/<elementId>`: the two paths inventaire.io's web client
    /// gives a list.
    static func list(at components: [String]) -> DeepLink? {
        guard components.first == "lists", components.count > 1, isCouchId(components[1]) else { return nil }

        switch components.count {
        case 2:
            return .list(id: components[1], elementId: nil)
        case 4 where components[2] == "element" && isCouchId(components[3]):
            return .list(id: components[1], elementId: components[3])
        default:
            return nil
        }
    }

    /// `entity/<uri>`, `users/<username>`, `groups/<slug>`: a page named by one segment.
    static func page(at components: [String]) -> DeepLink? {
        guard components.count == 2 else { return nil }

        let value: String = components[1]
        switch components[0] {
        case "entity" where value.wholeMatch(of: /(?:isbn|wd|inv):[A-Za-z0-9-]+/) != nil:
            return .entity(uri: value)
        case "users" where value.wholeMatch(of: Self.username) != nil:
            return .user(username: value)
        case "groups" where value.wholeMatch(of: Self.slug) != nil:
            return .group(slug: value)
        default:
            return nil
        }
    }

    /// A document id in inventaire.io's CouchDB: 32 lower-case hexadecimal digits.
    static func isCouchId(_ segment: String) -> Bool {
        segment.wholeMatch(of: /[0-9a-f]{32}/) != nil
    }
}
