//
//  CreateBookEditionNotes.swift
//  ReCIT_iOS
//
//  The two sentences under the cover and the ISBN: the language the ISBN gave, when it gave
//  one, and that what is written here becomes public.
//
//  See PRD 0015 and PRD 0021.
//

import SwiftUI

struct CreateBookEditionNotes: View {
    let draft: NewBookDraft

    var body: some View {
        VStack(alignment: .leading, spacing: .xSmall) {
            // Only when the ISBN has answered. Saying nothing is the honest state when the group
            // has no language or the call did not come back.
            if let language = draft.language?.localizedName {
                Text("create_book.language \(language)")
                    .accessibilityIdentifier("e2e.createBook.language")
            }

            Text("create_book.public_notice")
        }
        .textStyle(.footnote200)
        .foregroundStyle(.foregroundSecondary)
    }
}
