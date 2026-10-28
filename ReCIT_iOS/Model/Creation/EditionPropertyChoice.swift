//
//  EditionPropertyChoice.swift
//  ReCIT_iOS
//
//  One value a property allows among a fixed few: the entity uri the claim sends, and the
//  catalogue key of its name. The lists are the server's own (`GET /api/data/property-values`),
//  read on 2026-10-28: anything else is refused.
//

import Foundation

struct EditionPropertyChoice: Hashable, Identifiable, Sendable {
    let uri: String
    /// The catalogue key of its name.
    let label: String

    var id: String { uri }
}
