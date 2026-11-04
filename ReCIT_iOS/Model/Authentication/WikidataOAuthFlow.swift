//
//  WikidataOAuthFlow.swift
//  ReCIT_iOS
//
//  Linking a Wikidata account, as inventaire.io runs it: `GET /api/auth/wikidata-oauth` on a
//  signed-in session redirects to wikidata.org, which asks the reader to allow inventaire.io to
//  edit in their name, then comes back to the same endpoint, which stores the tokens on the
//  account and redirects once more — to `https://inventaire.io<redirect>`. OAuth 1.0a, three
//  legs, all of them followed by the browser: the app only sees where the last one lands.
//
//  Pure, on the pattern of `SessionExpiry`: the address to open and the address that says it is
//  over, without a web view. Verified on inventaire.io's source (Codeberg,
//  `server/controllers/auth/wikidata_oauth.ts`).
//

import Foundation

enum WikidataOAuthFlow {

    /// The key `GET /api/user` lists in `enabledOAuth` once the tokens are stored.
    static let provider: String = "wikidata"

    /// Where the server sends the browser when it is done. A page of the website, which the web
    /// view never loads: reaching it is the signal, and the sheet closes on it.
    static let returnPath: String = "/settings/account"

    /// Wikimedia's page listing the applications an account has allowed, where the access given
    /// to inventaire.io is taken back. inventaire.io itself has no way to unlink.
    static let manageGrantsURL: URL = .init(string: "https://meta.wikimedia.org/wiki/Special:OAuthManageMyGrants")!

    /// The address the web view opens, on the server the app talks to.
    static func startURL(baseURL: URL) -> URL {
        baseURL
            .appending(path: "api/auth/wikidata-oauth")
            .appending(queryItems: [.init(name: "redirect", value: returnPath)])
    }

    /// Whether the browser is being sent back to the website: the tokens are stored, or the
    /// server gave up. Either way the web view has nothing left to show, and the account is read
    /// again to know which.
    static func isReturn(_ url: URL, baseURL: URL) -> Bool {
        url.host() == baseURL.host() && url.path() == returnPath
    }
}
