//
//  ListReadOnlyCommentRow.swift
//  ReCIT_iOS
//
//  The comment on an element of a friend's list: their words, to be read. « Mon commentaire »
//  is a field and would lie here — it is not mine, and nothing may write it. See PRD 0031.
//

import SwiftUI

struct ListReadOnlyCommentRow: View {
    let comment: String

    var body: some View {
        VStack(alignment: .leading, spacing: .xSmall) {
            Text("list.detail.comment.other")
                .textStyle(.footnote200)
                .foregroundStyle(.foregroundSecondary)

            Text(comment)
                .textStyle(.content300)
                .foregroundStyle(.foregroundDefault)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
