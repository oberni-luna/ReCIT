//
//  CreateBookEditionNotes.swift
//  ReCIT_iOS
//
//  The sentences under the edition: the language the ISBN gave, when it gave one, and that
//  what is written here becomes public — said of the edition alone in « Nouvelle édition », of
//  the work and the edition in « Nouvelle œuvre ».
//
//  See PRD 0015 and PRD 0021.
//

import SwiftUI

struct CreateBookEditionNotes: View {
    let draft: NewBookDraft
    var notice: LocalizedStringKey = "create_book.public_notice"

    var body: some View {
        VStack(alignment: .leading, spacing: .xSmall) {
            // Only when the ISBN has answered. Saying nothing is the honest state when the group
            // has no language or the call did not come back.
            if let language = draft.language?.localizedName {
                Text("create_book.language \(language)")
                    .accessibilityIdentifier("e2e.createBook.language")
            }

            Text(notice)
        }
        .textStyle(.footnote200)
        .foregroundStyle(.foregroundSecondary)
    }
}
