//
//  CreateBookFailureBanner.swift
//  ReCIT_iOS
//
//  What a failed publication says, in the reader's terms, at the head of whichever screen
//  published: « Nouvelle édition », « Nouvelle œuvre » or « Œuvre déjà connue ».
//
//  The first line of every one of them is the same fact: nothing was created on inventaire.io.
//  A contributor who fears having made a duplicate will not press the button again, and the
//  book stays in their hand for nothing.
//
//  See PRD 0015 and PRD 0026.
//

import SwiftUI

struct CreateBookFailureBanner: View {
    let failure: CreateBookFailure

    var body: some View {
        HStack(alignment: .top, spacing: .small) {
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(.foregroundError)

            VStack(alignment: .leading, spacing: .xSmall) {
                Text(String(localized: failure.title))
                    .textStyle(.content400Bold)
                    .foregroundStyle(.foregroundError)

                Text(String(localized: failure.explanation))
                    .textStyle(.footnote200)
                    .foregroundStyle(.foregroundDefault)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.all, .sMedium)
        .background(.backgroundError)
        .clipShape(.rect(cornerRadius: DesignSystem.CornerRadius.medium))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("e2e.createBook.failure")
    }
}
