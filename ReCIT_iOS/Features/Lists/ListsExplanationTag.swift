//
//  ListsExplanationTag.swift
//  ReCIT_iOS
//
//  The paper tag that says what a list is, by setting it beside an étagère: one arranges the
//  books you have, the other keeps in mind the ones you don't. Nothing to press — it is the
//  only paper in the app that is not a button, and it says so by carrying no chevron and no
//  hit target.
//

import SwiftUI

struct ListsExplanationTag: View {
    var body: some View {
        VStack(alignment: .leading, spacing: .small) {
            Label {
                Text("lists.empty.explain.title")
                    .textStyle(.content400Bold)
            } icon: {
                Image(systemName: "list.bullet")
            }

            Text("lists.empty.explain.shelf")
                .textStyle(.content300)
            Text("lists.empty.explain.list")
                .textStyle(.content300)
        }
        .foregroundStyle(ShelfPalette.labelInk)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, .medium)
        .padding(.vertical, .sMedium)
        .shelfPaper(text: String(localized: "lists.empty.explain.title"))
        .accessibilityElement(children: .combine)
    }
}
