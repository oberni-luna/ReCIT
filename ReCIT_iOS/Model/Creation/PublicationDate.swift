//
//  PublicationDate.swift
//  ReCIT_iOS
//
//  An edition's `wdt:P577` as inventaire.io stores it: a year, a month or a day — `2023`,
//  `2023-03`, `2023-03-15` — never more precise than what the book prints. The website's
//  `isSimpleDay` accepts exactly those three shapes.
//

import Foundation

struct PublicationDate: Hashable, Sendable {

    enum Precision: Int, CaseIterable, Hashable, Sendable {
        case year
        case month
        case day
    }

    var year: Int
    /// 1 to 12; ignored below `.month`.
    var month: Int
    /// 1 to 31; ignored below `.day`.
    var day: Int
    var precision: Precision

    init(year: Int, month: Int = 1, day: Int = 1, precision: Precision) {
        self.year = year
        self.month = month
        self.day = day
        self.precision = precision
    }

    /// Reads a claim. `nil` for anything but the three shapes, or a month or a day out of range.
    init?(_ claim: String) {
        let parts: [Int?] = claim.split(separator: "-", omittingEmptySubsequences: false).map { Int($0) }
        guard (1...3).contains(parts.count), parts.allSatisfy({ $0 != nil }),
              let year = parts[0], year > 0, year < 10_000 else { return nil }

        let month: Int = parts.count > 1 ? parts[1] ?? 0 : 1
        let day: Int = parts.count > 2 ? parts[2] ?? 0 : 1
        guard (1...12).contains(month), (1...31).contains(day) else { return nil }

        self.init(year: year, month: month, day: day, precision: Precision(rawValue: parts.count - 1) ?? .year)
    }

    /// The value as it goes on the wire.
    var claim: String {
        let year: String = Self.padded(self.year, to: 4)
        switch precision {
        case .year: return year
        case .month: return "\(year)-\(Self.padded(month, to: 2))"
        case .day: return "\(year)-\(Self.padded(month, to: 2))-\(Self.padded(day, to: 2))"
        }
    }

    private static func padded(_ number: Int, to width: Int) -> String {
        let digits: String = String(number)
        return String(repeating: "0", count: max(0, width - digits.count)) + digits
    }

    /// The date as the form prints it, at its own precision: « 2023 », « mars 2023 »,
    /// « 15 mars 2023 ».
    var displayed: String {
        let components: DateComponents = .init(year: year, month: month, day: day)
        guard let date = Calendar(identifier: .gregorian).date(from: components) else { return claim }

        switch precision {
        case .year:
            return String(year)
        case .month:
            return date.formatted(.dateTime.month(.wide).year())
        case .day:
            return date.formatted(.dateTime.day().month(.wide).year())
        }
    }

    /// The day as a `Date`, for the date picker.
    var date: Date {
        Calendar(identifier: .gregorian).date(from: .init(year: year, month: month, day: day)) ?? .now
    }

    /// Sets the date from the picker, keeping the precision.
    mutating func set(_ date: Date) {
        let components: DateComponents = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: date)
        year = components.year ?? year
        month = components.month ?? month
        day = components.day ?? day
    }
}
