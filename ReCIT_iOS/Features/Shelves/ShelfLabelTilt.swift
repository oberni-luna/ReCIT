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
//  Two things the fold must not do. It folds over Unicode *scalars*, not ASCII bytes:
//  French shelf names are full of accented characters and an ASCII fold drops them, so
//  "Classiques français" would lean like everything else. And it never touches
//  `String.hashValue`, which is seeded per process — the labels would lean differently on
//  every launch, a failure invisible within any single run, which is why a test pins it.
//

import Foundation

enum ShelfLabelTilt {

    /// The widest a label leans, either way. Enough to read as hand-applied, little
    /// enough not to read as broken.
    static let maximumDegrees: Double = 1

    /// How many distinct angles the range is cut into. Odd, so dead upright is reachable.
    private static let steps: UInt64 = 2001

    /// The lean, in degrees, for a label carrying `text`. Always within
    /// `-maximumDegrees...maximumDegrees`, and always the same for the same text.
    static func degrees(for text: String) -> Double {
        let bucket: UInt64 = mix(hash(of: text)) % steps
        let unit: Double = Double(bucket) / Double(steps - 1) * 2 - 1
        return unit * maximumDegrees
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
