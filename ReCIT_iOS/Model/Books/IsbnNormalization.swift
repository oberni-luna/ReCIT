//
//  IsbnNormalization.swift
//  ReCIT_iOS
//
//  The one form two ISBNs are compared in: thirteen digits, no hyphen, no space. An ISBN-10 is
//  turned into the ISBN-13 it stands for — `978` in front, the check digit computed again — so
//  an edition that records only `2-07-036822-X` and one that records `978-2-07-036822-8` are seen
//  as the same book, which is what they are.
//
//  inventaire.io compares them its own way when it merges (`normalizeIsbn`); this is the app's
//  reading, used only to decide what to show as a duplicate. A string that is neither ten nor
//  thirteen characters long is no ISBN at all and brings no two editions together. Check digits
//  are not verified: the server validates an ISBN when it is written, and two records of the same
//  mistyped number are still one number.
//
//  See PRD 0028.
//

import Foundation

enum IsbnNormalization {

    /// The ISBN-13 `raw` stands for, as thirteen digits — or `nil` when `raw` has the shape of neither.
    static func normalized(_ raw: String?) -> String? {
        guard let raw else { return nil }
        let characters: String = raw.uppercased().filter { $0.isASCII && ($0.isNumber || $0 == "X") }

        switch characters.count {
        case 13:
            guard characters.allSatisfy(\.isNumber) else { return nil }
            return characters
        case 10:
            guard characters.prefix(9).allSatisfy(\.isNumber),
                  let checkDigit = isbn13CheckDigit(of: "978" + characters.prefix(9))
            else { return nil }
            return "978" + characters.prefix(9) + String(checkDigit)
        default:
            return nil
        }
    }

    private static func isbn13CheckDigit(of digits: some StringProtocol) -> Character? {
        let values: [Int] = digits.compactMap(\.wholeNumberValue)
        guard values.count == 12 else { return nil }
        let sum: Int = values.enumerated().reduce(0) { total, element in
            total + element.element * (element.offset.isMultiple(of: 2) ? 1 : 3)
        }
        return Character(String((10 - sum % 10) % 10))
    }
}
