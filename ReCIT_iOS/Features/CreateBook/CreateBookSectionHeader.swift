//
//  CreateBookSectionHeader.swift
//  ReCIT_iOS
//
//  The header of a section in the book creation, in the app's section header style rather than
//  the system's: `Section Header` (`28:164`) in the Figma file, as the Réseau screens set theirs.
//
//  See PRD 0021.
//

import SwiftUI

struct CreateBookSectionHeader: View {
    let title: LocalizedStringKey

    init(_ title: LocalizedStringKey) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .textStyle(.action200)
    }
}
