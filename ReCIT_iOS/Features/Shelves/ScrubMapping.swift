//
//  ScrubMapping.swift
//  ReCIT_iOS
//
//  Pure mapping from a finger position over a shelf's books zone to a book index.
//  Extracted from the UIKit scrub recognizer so it can be unit-tested without UIKit.
//  Mapping is linear across the books width. See PRD 0002.
//

import CoreGraphics

enum ScrubMapping {
    /// The index of the book under `(x, y)` within a books zone of `width`×`height`, or
    /// `nil` when the point is outside the zone or there are no books.
    static func index(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, count: Int) -> Int? {
        guard count > 0, width > 0 else { return nil }
        guard x >= 0, x <= width, y >= 0, y <= height else { return nil }
        let slot: CGFloat = width / CGFloat(count)
        return min(Int(x / slot), count - 1)
    }
}
