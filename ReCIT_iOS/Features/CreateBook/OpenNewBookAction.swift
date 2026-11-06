//
//  OpenNewBookAction.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 06/11/2026.
//

import SwiftUI

/// Opens « Nouveau livre » for a book inventaire.io does not have — from the absence of
/// « Sur inventaire.io », set up once by `SearchTabView`, which holds the sheet, its drafts and the
/// navigation stack the new book opens on.
struct OpenNewBookAction: Equatable {
    private let action: @MainActor (NewBookOrigin) -> Void

    init(_ action: @escaping @MainActor (NewBookOrigin) -> Void) {
        self.action = action
    }

    static func == (lhs: OpenNewBookAction, rhs: OpenNewBookAction) -> Bool {
        true
    }

    func callAsFunction(_ origin: NewBookOrigin) {
        action(origin)
    }
}
