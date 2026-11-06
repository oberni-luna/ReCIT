//
//  GroupPictureEdit.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 06/11/2026.
//

import Foundation

/// What « Réglages du groupe » has done to the group's photo since it opened. Nothing leaves the
/// phone before « Enregistrer », so a photo picked then replaced, or the sheet closed, costs
/// nothing.
enum GroupPictureEdit: Equatable, Sendable {
    case unchanged
    case replaced(Data)
    case removed

    /// The new photo's bytes; `nil` when the photo is taken away, or left alone.
    var imageData: Data? {
        if case let .replaced(data) = self { data } else { nil }
    }

    /// Whether the slot shows a photo, for a group whose photo on the server is `savedPictureURL`.
    func showsPicture(savedPictureURL: String?) -> Bool {
        switch self {
        case .unchanged: savedPictureURL != nil
        case .replaced: true
        case .removed: false
        }
    }

    /// Whether « Enregistrer » has a photo to write: taking away a photo the group does not have
    /// is nothing.
    func isChange(from savedPictureURL: String?) -> Bool {
        switch self {
        case .unchanged: false
        case .replaced: true
        case .removed: savedPictureURL != nil
        }
    }
}
