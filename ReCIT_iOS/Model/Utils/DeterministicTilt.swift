//
//  DeterministicTilt.swift
//  ReCIT_iOS
//
//  How far something leans, derived from a piece of text and nothing else. Extracted from
//  `ShelfLabelTilt`, which now asks it for ±1°, so that the sorting surface's piled covers
//  can ask it for ±10° without a second implementation of the same arithmetic — and
//  without a second chance to make the two mistakes below. See PRD 0009.
//
//  Deriving the angle from the text means nothing is persisted: no schema change, no
//  migration, and an angle for text that has no object behind it (an empty-state label, a
//  book whose copy is not in the store). Accepted consequence: renaming re-rolls the lean.
//
//  Two things the fold must not do, both invisible by eye and both pinned by tests.
//
//  It folds over Unicode **scalars**, not ASCII bytes: French titles and shelf names are
//  full of accented characters, and an ASCII fold drops them — so « Classiques français »
//  and « Classiques francais » would lean alike, and worse, a shelf of similarly-accented
//  names would share one angle.
//
//  It never touches `String.hashValue`, which is **seeded per process**: the leans would be
//  different on every launch, a failure that looks perfect within any single run.
//

import Foundation

enum DeterministicTilt {

    /// How many distinct angles the range is cut into. Odd, so dead upright is reachable:
    /// a pile where nothing is ever straight reads as a rendering bug, not as handling.
    private static let steps: UInt64 = 2001

    /// The lean, in degrees, for `text`, within `-amplitude...amplitude`. Always the same
    /// for the same text and the same amplitude, in this process and in every other.
    static func degrees(for text: String, amplitude: Double) -> Double {
        let bucket: UInt64 = mix(hash(of: text)) % steps
        let unit: Double = Double(bucket) / Double(steps - 1) * 2 - 1
        return unit * amplitude
    }

    /// djb2 over Unicode scalars.
    private static func hash(of text: String) -> UInt64 {
        text.unicodeScalars.reduce(into: UInt64(5381)) { hash, scalar in
            hash = hash &* 33 &+ UInt64(scalar.value)
        }
    }

    /// splitmix64's finalizer. djb2 alone leaves neighbouring texts in neighbouring
    /// buckets, which on a shelf of similarly-shaped French names reads as every label
    /// leaning the same way; this scatters the bits before the modulo sees them.
    private static func mix(_ value: UInt64) -> UInt64 {
        var z: UInt64 = value
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
