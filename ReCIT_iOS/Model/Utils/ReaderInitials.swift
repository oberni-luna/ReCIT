//
//  ReaderInitials.swift
//  ReCIT_iOS
//
//  The letters a reader without a photo is drawn with — on a tinted disc, in the lists and in
//  the network graph (PRD 0019, Q20).
//
//  inventaire.io usernames are handles, not names: « olivier_berni », « JeanLuc », « Léa ». A
//  handle made of several words gets one letter per word, so « olivier_berni » reads « OB » and
//  not « OL »; a handle that is one word gets its first two letters, so « Léa » reads « LÉ »
//  rather than a lone « L ». Words are cut at `_`, `.`, `-`, whitespace, and wherever a lowercase
//  letter is followed by an uppercase one. Two letters at most: the disc holds two.
//
//  Letters are grapheme clusters, never bytes or scalars, so an accent stays on its letter
//  (« Aïcha » → « AÏ ») and an emoji stays whole.
//
//  `nonisolated`: the target defaults to the main actor, and this is arithmetic on a string that
//  the graph's pure modules call off it.
//

import Foundation

nonisolated enum ReaderInitials {

    /// The characters that separate two words of a handle, besides whitespace.
    static let separators: Set<Character> = ["_", ".", "-"]

    /// At most two uppercased letters for `username`; the empty string for a handle with no
    /// letters at all.
    static func of(_ username: String) -> String {
        let words: [String] = words(in: username)
        let letters: [Character] = switch words.count {
        case 0: []
        case 1: Array(words[0].prefix(2))
        default: words.prefix(2).compactMap(\.first)
        }
        return String(letters).uppercased()
    }

    /// The words of a handle, in order, with the separators dropped and no empty word.
    static func words(in username: String) -> [String] {
        var words: [String] = []
        var current: String = ""
        var previous: Character?

        for character in username {
            if isSeparator(character) {
                if current.isEmpty == false {
                    words.append(current)
                    current = ""
                }
                previous = nil
                continue
            }
            if let previous, previous.isLowercase, character.isUppercase, current.isEmpty == false {
                words.append(current)
                current = ""
            }
            current.append(character)
            previous = character
        }
        if current.isEmpty == false {
            words.append(current)
        }
        return words
    }

    private static func isSeparator(_ character: Character) -> Bool {
        separators.contains(character) || character.isWhitespace
    }
}
