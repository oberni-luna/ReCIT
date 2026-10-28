//
//  CreateBookFailure+EditEntity.swift
//  ReCIT_iOS
//
//  What a failed save of « Modifier l'œuvre » or « Modifier l'auteur·ice » says: an edition's
//  words, but for the refusal, which cannot blame a title or a cover.
//

import Foundation

extension CreateBookFailure {

    var entityEditExplanation: String.LocalizationValue {
        switch self {
        case .refused: "edit_entity.failure.refused.body"
        default: editionEditExplanation
        }
    }
}
