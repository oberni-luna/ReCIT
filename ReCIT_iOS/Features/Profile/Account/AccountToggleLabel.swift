//
//  AccountToggleLabel.swift
//  ReCIT_iOS
//
//  A switch's label in the account's settings: what it is, and what it does in a footnote under
//  it — `Row / Toggle` in the Figma file, as `GroupAccessSection` draws it.
//

import SwiftUI

struct AccountToggleLabel: View {
    let title: LocalizedStringKey
    var detail: LocalizedStringKey?

    var body: some View {
        VStack(alignment: .leading, spacing: .xxSmall) {
            Text(title)
                .textStyle(.content300)
                .foregroundStyle(.foregroundDefault)

            if let detail {
                Text(detail)
                    .textStyle(.footnote200)
                    .foregroundStyle(.foregroundSecondary)
            }
        }
    }
}
