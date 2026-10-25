//
//  CreateBookFailure+EditEdition.swift
//  ReCIT_iOS
//
//  The same three failures as a publication's, said of a change to an edition. Nothing is
//  created here, so « rien n'a été créé » would be false; what the reader needs instead is that
//  what they wrote is still on the screen, and that trying again sends only what has not landed.
//

import Foundation

extension CreateBookFailure {

    var editionEditTitle: String.LocalizationValue {
        switch self {
        case .needsAccount: "edit_edition.failure.account.title"
        case .refused: "edit_edition.failure.refused.title"
        case .network: "edit_edition.failure.network.title"
        }
    }

    var editionEditExplanation: String.LocalizationValue {
        switch self {
        case .needsAccount: "edit_edition.failure.account.body"
        case .refused: "edit_edition.failure.refused.body"
        case .network: "edit_edition.failure.network.body"
        }
    }
}
