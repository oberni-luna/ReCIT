//
//  ListCrossFade.swift
//  ReCIT_iOS
//
//  What makes the move from one book to the next a dissolve rather than a jump: the content is
//  keyed on the selected uri, so a new book replaces it as a whole, and the old one fades out as
//  the new one fades in, under one short ease. Each row of a list's screen wraps what it says
//  about the selected book in one of these. See PRD 0029.
//

import SwiftUI

struct ListCrossFade<Content: View>: View {
    let id: String
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            content
                .id(id)
                .transition(.opacity)
        }
        .animation(.easeInOut(duration: 0.25), value: id)
    }
}
