//
//  SyncingInlineRow.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 03/08/2026.
//

import SwiftUI

/// Compact "syncing…" row for use inside a `List` section, where a full-screen
/// `SyncingPlaceholderView` would be out of place. Marks a section whose first
/// sync hasn't completed yet.
struct SyncingInlineRow: View {
    let message: LocalizedStringKey

    init(message: LocalizedStringKey = "sync.loading") {
        self.message = message
    }

    var body: some View {
        HStack(spacing: .small) {
            ProgressView()
            Text(message)
                .textStyle(.content300)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    List {
        SyncingInlineRow()
    }
}
