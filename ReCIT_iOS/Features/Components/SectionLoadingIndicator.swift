//
//  SectionLoadingIndicator.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 29/10/2026.
//

import SwiftUI

/// A small spinner set after a section header's label while the section is being completed from
/// the network. The cached rows are already on screen: this only says that more may come.
struct SectionLoadingIndicator: View {
    var body: some View {
        ProgressView()
            .controlSize(.small)
            // The header's own colour, not the accent: it says « more may come », not « wait ».
            .tint(.foregroundSecondary)
            .accessibilityLabel(Text("section.refreshing"))
    }
}

#Preview {
    List {
        Section {
            Text(verbatim: "Le Petit Prince")
        } header: {
            HStack(spacing: .small) {
                Text(verbatim: "Works by Antoine de Saint-Exupéry")
                SectionLoadingIndicator()
            }
        }
    }
}
