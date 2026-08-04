//
//  SyncingPlaceholderView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 03/08/2026.
//

import SwiftUI

/// Full-screen placeholder shown while a domain's first sync is still running.
/// Distinguishes "not synced yet" from a genuinely empty, already-synced screen.
struct SyncingPlaceholderView: View {
    let message: LocalizedStringKey

    init(message: LocalizedStringKey = "sync.loading") {
        self.message = message
    }

    var body: some View {
        VStack(alignment: .center, spacing: .medium) {
            ProgressView()
                .controlSize(.large)

            Text(message)
                .textStyle(.content300)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.all, .large)
    }
}

#Preview {
    SyncingPlaceholderView()
}
