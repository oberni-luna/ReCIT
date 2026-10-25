//
//  EnvironmentValues+BibliographicDataHelp.swift
//  ReCIT_iOS
//
//  Where `BibliographicDataHelpAction` is found: set by `NewBookFlowView`, read by the « ? » of
//  each screen of the book creation and by the notice's « En savoir plus ».
//

import SwiftUI

extension EnvironmentValues {
    @Entry var showBibliographicDataHelp: BibliographicDataHelpAction = .init {}
}
