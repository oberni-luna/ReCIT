//
//  ListSelectedTitle.swift
//  ReCIT_iOS
//
//  The selected element's title, centred under the cover flow, and under it its authors — or,
//  for an author, what inventaire.io says they are. See PRD 0029.
//
//  The block always takes the height of a two-line title over a one-line byline, and its text
//  sits on the bottom of it: going from one element to the next — a short title, a long one, a
//  work with no author — moves nothing below it. A longer title or byline is cut.
//

import SwiftUI

struct ListSelectedTitle: View {
    let uri: String
    let listType: EntityListType

    var body: some View {
        ListElementReader(uri: uri, listType: listType) { entity in
            ZStack(alignment: .bottom) {
                // The height held: two lines of title over one of byline, in their own styles so it
                // follows Dynamic Type.
                VStack(spacing: .xxSmall) {
                    Text(verbatim: " ")
                        .textStyle(.content400Bold)
                        .lineLimit(2, reservesSpace: true)

                    Text(verbatim: " ")
                        .textStyle(.content300)
                }
                .hidden()
                .accessibilityHidden(true)

                VStack(spacing: .xxSmall) {
                    Text(entity?.title ?? "")
                        .textStyle(.content400Bold)
                        .foregroundStyle(.foregroundDefault)
                        .lineLimit(2)

                    if let byline = entity?.byline, byline.isEmpty == false {
                        Text(byline)
                            .textStyle(.content300)
                            .foregroundStyle(.foregroundSecondary)
                            .lineLimit(1)
                    }
                }
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
        }
    }
}
