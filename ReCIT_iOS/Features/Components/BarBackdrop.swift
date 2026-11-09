//
//  BarBackdrop.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 09/11/2026.
//

import SwiftUI

/// The bars' own material, stopping at its foot on a hairline as a navigation bar does: what a
/// header held under the navigation bar stands on.
struct BarBackdrop: View {
    var body: some View {
        Rectangle()
            .fill(.bar)
            .overlay(alignment: .bottom) {
                Divider()
            }
    }
}

#Preview {
    Text(verbatim: "Livres • 8 | Présentation")
        .padding()
        .frame(maxWidth: .infinity)
        .background {
            BarBackdrop()
        }
}
