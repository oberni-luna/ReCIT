//
//  ListAddResultRow.swift
//  ReCIT_iOS
//
//  A result of the search that adds to a list: the book or the author, and at its right the small
//  « + » that adds it — or a check when the list already holds it, or a spinner while the works of
//  a book are being read. `List / Add Result` in the Figma file (`855:645`).
//
//  The check is not a button. inventaire.io keeps a work once per list, so there is nothing for it
//  to do; it is there to answer « is it already in? » before the question is asked.
//
//  See PRD 0029.
//

import SwiftUI

struct ListAddResultRow: View {
    let imageUrl: String?
    let title: String
    let subtitle: String?
    let isRound: Bool
    let isInList: Bool
    let isBusy: Bool
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: .sMedium) {
            CellThumbnail(
                imageUrl: imageUrl,
                cornerRadius: isRound ? .full : .minimal,
                shape: isRound ? .square : .portrait
            )

            VStack(alignment: .leading, spacing: .xxSmall) {
                Text(title)
                    .textStyle(.content400Bold)
                    .foregroundStyle(.foregroundDefault)
                    .lineLimit(2)

                if let subtitle, subtitle.isEmpty == false {
                    Text(subtitle)
                        .textStyle(.footnote200)
                        .foregroundStyle(.foregroundSecondary)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            trailing
        }
    }

    @ViewBuilder
    private var trailing: some View {
        if isInList {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(.foregroundTinted)
                .accessibilityLabel(Text("list.add.in_list"))
        } else if isBusy {
            ProgressView()
        } else {
            Button("list.add.action", systemImage: "plus", action: onAdd)
                .labelStyle(.iconOnly)
                .buttonStyle(.pill(.tinted))
                .accessibilityIdentifier("e2e.list.add.result")
        }
    }
}
