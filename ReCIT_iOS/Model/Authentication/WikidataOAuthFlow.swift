//
//  WikidataOAuthFlow.swift
//  ReCIT_iOS
//
//  The key inventaire.io lists in `enabledOAuth` once an account is linked to Wikidata. Linking
//  is done on the inventaire.io website, not in the app: the app only reads whether it is.
//

import Foundation

enum WikidataOAuthFlow {

    /// The key `GET /api/user` lists in `enabledOAuth` once the tokens are stored.
    static let provider: String = "wikidata"
}
