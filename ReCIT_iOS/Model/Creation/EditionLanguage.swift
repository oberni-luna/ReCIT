//
//  EditionLanguage.swift
//  ReCIT_iOS
//
//  What the ISBN says about the language a book is written in. The registration group of an
//  ISBN is handed out by language area — `978-2` is the French-language group — so the code
//  the camera read already answers a question the form would otherwise have to ask.
//
//  Two spellings of the same fact, because two things need it: the wikidata uri goes into the
//  edition's `wdt:P407` claim, and the language code names the labels of the entities being
//  created.
//
//  See PRD 0015.
//

import Foundation

struct EditionLanguage: Equatable, Sendable {

    /// The wikidata entity of the language — `wd:Q150` for French.
    let uri: String

    /// The two-letter code — `fr`.
    let code: String

    /// The language's name, in the reader's own language, for the one line the form shows
    /// about it. `nil` when the system has no name for that code, in which case the form says
    /// nothing rather than printing a code at somebody.
    var localizedName: String? {
        Locale.current.localizedString(forLanguageCode: code)
    }
}
