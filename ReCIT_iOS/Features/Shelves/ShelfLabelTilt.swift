//
//  ShelfLabelTilt.swift
//  ReCIT_iOS
//
//  How far a paper label leans, derived from the text written on it and nothing else.
//  Deriving it from the text rather than from the shelf keeps one rule for a real
//  étagère's label and for the empty-state label, which has no shelf behind it, and means
//  nothing has to be persisted — so no schema change and no migration. Accepted
//  consequence: renaming an étagère re-rolls its tilt. See PRD 0003.
//
//  The arithmetic moved to `DeterministicTilt` when the sorting surface needed the same
//  rule at ±10° for its piled covers (PRD 0009). What stays here is this label's own
//  amplitude, which is the only part of it that is about paper labels. The two traps the
//  fold must avoid — an ASCII fold that drops accents, and `String.hashValue`, which is
//  seeded per process — are documented and pinned where the fold now lives.
//

import Foundation

enum ShelfLabelTilt {

    /// The widest a label leans, either way. Enough to read as hand-applied, little
    /// enough not to read as broken.
    static let maximumDegrees: Double = 1

    /// The lean, in degrees, for a label carrying `text`. Always within
    /// `-maximumDegrees...maximumDegrees`, and always the same for the same text.
    static func degrees(for text: String) -> Double {
        DeterministicTilt.degrees(for: text, amplitude: maximumDegrees)
    }
}
