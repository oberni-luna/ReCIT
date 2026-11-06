//
//  EnvironmentValues+OpenNewBook.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 06/11/2026.
//

import SwiftUI

extension EnvironmentValues {
    /// Where `OpenNewBookAction` is found: set by `SearchTabView`, read by `SearchRemoteSection`.
    @Entry var openNewBook: OpenNewBookAction = .init { _ in }
}
