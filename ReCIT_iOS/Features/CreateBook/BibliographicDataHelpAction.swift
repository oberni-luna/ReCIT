//
//  BibliographicDataHelpAction.swift
//  ReCIT_iOS
//
//  Opens the help about bibliographic data — from the « ? » of any screen of the book creation,
//  and from the notice's « En savoir plus ». One sheet, set up once by `NewBookFlowView`, so
//  that every way of asking opens the same one.
//
//  See PRD 0021.
//

import SwiftUI

struct BibliographicDataHelpAction: Equatable {
    private let action: @MainActor () -> Void

    init(_ action: @escaping @MainActor () -> Void) {
        self.action = action
    }

    func callAsFunction() {
        action()
    }

    static func == (lhs: BibliographicDataHelpAction, rhs: BibliographicDataHelpAction) -> Bool {
        true
    }
}
