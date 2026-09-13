//
//  ReportButton.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 12/09/2026.
//

import LBSnackBar
import SwiftUI

/// The « Signalement » line inside a "…" menu: it hands a pre-filled mail to the user's mail
/// client, addressed to the moderation mailbox.
///
/// It sends nothing by itself — the user still writes and presses send — which is the point:
/// a report is a person's word, and the app must not put one in their mouth. When no mail
/// client answers, the address is shown in a snackbar so the report is still possible.
struct ReportButton: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.snackBar) private var snackBar

    let draft: ReportMailDraft

    var body: some View {
        Button("report.action", systemImage: "exclamationmark.bubble") {
            guard let url = draft.mailtoURL else {
                showUnavailable()
                return
            }
            openURL(url) { accepted in
                if !accepted {
                    showUnavailable()
                }
            }
        }
    }

    private func showUnavailable() {
        snackBar.show {
            SnackBarView(
                title: String(localized: "report.mail_unavailable"),
                subtitle: ReportMailDraft.recipient,
                onDismiss: nil
            )
        }
    }
}
