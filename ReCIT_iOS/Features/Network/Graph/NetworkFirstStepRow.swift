//
//  NetworkFirstStepRow.swift
//  ReCIT_iOS
//
//  One row of `NetworkFirstStepsCard` — `Row / Link`, `Tone=Tinted`: an action in
//  `foregroundTinted`, no icon, no chevron, the whole width touchable.
//

import SwiftUI

struct NetworkFirstStepRow: View {
    let title: LocalizedStringKey

    var body: some View {
        Text(title)
            .textStyle(.action300)
            .foregroundStyle(.foregroundTinted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, .medium)
            .padding(.vertical, .sMedium)
            .contentShape(.rect)
    }
}
