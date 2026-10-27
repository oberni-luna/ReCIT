//
//  EditionDuplicateReason.swift
//  ReCIT_iOS
//
//  Why two editions of one work look like the same book. PRD 0028.
//

import Foundation

enum EditionDuplicateReason: Equatable, Hashable, Sendable {
    /// Both carry the same ISBN, once ISBN-10 and ISBN-13 are read in one form.
    case sameIsbn
    /// One at least has no ISBN, and both name the same publisher and the same year.
    case probable
}
