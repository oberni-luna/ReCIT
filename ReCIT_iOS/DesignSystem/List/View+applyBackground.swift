//
//  View+applyBackground.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 06/03/2026.
//
import SwiftUI

extension View {
    func applyListBackground() -> some View {
        self
            .scrollContentBackground(.hidden)
            .background(.backgroundSecondary)
    }
}
