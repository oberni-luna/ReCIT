//
//  IsbnQuery.swift
//  ReCIT_iOS
//
//  Whether what was typed in Recherche is an ISBN, and which one.
//
//  `/api/search` is a full-text search over labels: it cannot find an edition, and it reads
//  « 978-2-234-09688-2 » as the words `978`, `2`, `234`… — which brought back « Divergente 2 »
//  and « Dragon Ball, tome 2 » rather than the book. inventaire.io's website recognises an ISBN
//  before it searches, and asks for the edition by its `isbn:` uri instead. This is the app's
//  half of that recognition.
//
//  **Strict on purpose.** `IsbnNormalization` keeps the digits of anything it is handed, which is
//  right for comparing two recorded ISBNs and wrong for a query: « Dune 1965 » is not a number to
//  look up. Here the query has to be nothing but digits, hyphens and spaces (and the `X` an
//  ISBN-10 may end on), and its check digit has to be right — a thirteen-digit number that is not
//  an ISBN goes to the text search like any other query, rather than to a lookup that would fail.
//
//  Pure — Foundation only — so it is driven by values in a test.
//

import Foundation

nonisolated enum IsbnQuery {

    /// The thirteen-digit ISBN `query` is, or `nil` when it is not one.
    static func isbn(in query: String) -> String? {
        let trimmed: String = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let allowed: Set<Character> = ["-", " ", "X", "x"]
        guard trimmed.allSatisfy({ $0.isASCII && ($0.isNumber || allowed.contains($0)) }) else { return nil }

        let characters: String = trimmed.uppercased().filter { $0.isNumber || $0 == "X" }

        switch characters.count {
        case 13:
            guard characters.allSatisfy(\.isNumber),
                  characters.hasPrefix("978") || characters.hasPrefix("979"),
                  hasValidIsbn13CheckDigit(characters)
            else { return nil }
            return characters
        case 10:
            guard hasValidIsbn10CheckDigit(characters) else { return nil }
            return IsbnNormalization.normalized(characters)
        default:
            return nil
        }
    }

    private static func hasValidIsbn13CheckDigit(_ digits: String) -> Bool {
        let values: [Int] = digits.compactMap(\.wholeNumberValue)
        guard values.count == 13 else { return false }
        let sum: Int = values.enumerated().reduce(0) { total, element in
            total + element.element * (element.offset.isMultiple(of: 2) ? 1 : 3)
        }
        return sum.isMultiple(of: 10)
    }

    /// Nine digits, then a digit or an `X` worth ten, weighted 10 down to 1 — a multiple of 11.
    private static func hasValidIsbn10CheckDigit(_ characters: String) -> Bool {
        guard characters.prefix(9).allSatisfy(\.isNumber) else { return false }
        let values: [Int] = characters.map { $0 == "X" ? 10 : ($0.wholeNumberValue ?? -1) }
        guard values.allSatisfy({ $0 >= 0 }) else { return false }
        let sum: Int = values.enumerated().reduce(0) { total, element in
            total + element.element * (10 - element.offset)
        }
        return sum.isMultiple(of: 11)
    }
}
