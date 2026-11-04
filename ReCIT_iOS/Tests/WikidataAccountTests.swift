//
//  WikidataAccountTests.swift
//  ReCIT_iOSTests
//
//  Linking a Wikidata account: the address the web view opens, the one that closes it, and
//  `enabledOAuth` read off `GET /api/user`.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@Suite("Wikidata account")
struct WikidataAccountTests {

    private let baseURL: URL = .init(string: "https://inventaire.io")!

    private func account(_ json: String) throws -> AccountSettings {
        let dto: UserDTO = try JSONDecoder().decode(UserDTO.self, from: Data(json.utf8))
        return .init(userDTO: dto)
    }

    private func userJSON(enabledOAuth: String?) -> String {
        let field: String = enabledOAuth.map { #", "enabledOAuth": \#($0)"# } ?? ""
        return #"{ "_id": "u1", "username": "OlivierB"\#(field) }"#
    }

    @Test("The web view opens the endpoint, asking to come back to the account settings")
    func startURL() {
        #expect(
            WikidataOAuthFlow.startURL(baseURL: baseURL).absoluteString
                == "https://inventaire.io/api/auth/wikidata-oauth?redirect=/settings/account"
        )
    }

    @Test("Only the return address on inventaire.io closes it, not the legs on wikidata.org")
    func returnAddress() throws {
        let back: URL = try #require(URL(string: "https://inventaire.io/settings/account"))
        let callback: URL = try #require(URL(string: "https://inventaire.io/api/auth/wikidata-oauth?oauth_verifier=v&oauth_token=t&redirect=/settings/account"))
        let authorize: URL = try #require(URL(string: "https://www.wikidata.org/wiki/Special:OAuth/authorize?oauth_token=t"))
        let elsewhere: URL = try #require(URL(string: "https://www.wikidata.org/settings/account"))

        #expect(WikidataOAuthFlow.isReturn(back, baseURL: baseURL))
        #expect(WikidataOAuthFlow.isReturn(callback, baseURL: baseURL) == false)
        #expect(WikidataOAuthFlow.isReturn(authorize, baseURL: baseURL) == false)
        #expect(WikidataOAuthFlow.isReturn(elsewhere, baseURL: baseURL) == false)
    }

    @Test("An account lists wikidata in enabledOAuth once linked")
    func linked() throws {
        #expect(try account(userJSON(enabledOAuth: #"["wikidata"]"#)).linksWikidata)
    }

    @Test("No wikidata in enabledOAuth, or no enabledOAuth at all, is not linked")
    func notLinked() throws {
        #expect(try account(userJSON(enabledOAuth: "[]")).linksWikidata == false)
        #expect(try account(userJSON(enabledOAuth: nil)).linksWikidata == false)
    }
}
