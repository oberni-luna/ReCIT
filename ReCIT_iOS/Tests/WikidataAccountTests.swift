//
//  WikidataAccountTests.swift
//  ReCIT_iOSTests
//
//  A linked Wikidata account: `enabledOAuth` read off `GET /api/user`.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@Suite("Wikidata account")
struct WikidataAccountTests {

    private func account(_ json: String) throws -> AccountSettings {
        let dto: UserDTO = try JSONDecoder().decode(UserDTO.self, from: Data(json.utf8))
        return .init(userDTO: dto)
    }

    private func userJSON(enabledOAuth: String?) -> String {
        let field: String = enabledOAuth.map { #", "enabledOAuth": \#($0)"# } ?? ""
        return #"{ "_id": "u1", "username": "OlivierB"\#(field) }"#
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
