//
//  EditionDuplicateTag.swift
//  ReCIT_iOS
//
//  The tag an edition's row carries in « Éditions »: « Même ISBN », « Doublon probable », or
//  « Doublon signalé » while inventaire.io's team has a merge task about it. PRD 0028.
//

import Foundation

nonisolated enum EditionDuplicateTag: Equatable, Hashable, Sendable {
    case sameIsbn
    case probable
    case reported

    init(_ reason: EditionDuplicateReason) {
        switch reason {
        case .sameIsbn:
            self = .sameIsbn
        case .probable:
            self = .probable
        }
    }
}
