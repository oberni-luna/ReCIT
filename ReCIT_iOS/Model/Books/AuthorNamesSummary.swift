//
//  AuthorNamesSummary.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 04/11/2026.
//

import Foundation

/// The authors a book row names under the title: the first three, then how many it leaves out.
struct AuthorNamesSummary: Sendable {
    static let maximumShownNames: Int = 3

    let shownNames: [String]
    let hiddenCount: Int

    /// « A, B, C », or « A, B, C et 98 autres » past three names.
    var text: String {
        let shown: String = shownNames.joined(separator: ", ")
        guard hiddenCount > 0 else { return shown }
        return "\(shown) \(String(localized: "inventory.authors.others \(hiddenCount)"))"
    }

    /// - Parameter names: every name, in the order the row shows them.
    init(_ names: [String]) {
        shownNames = Array(names.prefix(Self.maximumShownNames))
        hiddenCount = names.count - shownNames.count
    }
}
