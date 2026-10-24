//
//  AutoSortUnavailableView.swift
//  ReCIT_iOS
//
//  The one place auto-sort's three unavailability reasons are put into words, so the
//  settings entry point and the flow's own wall cannot describe the same reason two
//  different ways. Which reason gets which treatment is `AutoSortEntryPoint`'s job;
//  this only says it out loud.
//
//  The Settings button appears only where Settings can help — the rule
//  `ScannerPermissionView` already follows. Under a downloading model it would send
//  the user to a switch that is already flipped, and on an ineligible device to one
//  that does not exist.
//
//  See PRD 0006.
//

import SwiftUI

struct AutoSortUnavailableView: View {
    let entryPoint: AutoSortEntryPoint

    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: .medium) {
            Text(message)
                .textStyle(.content300)
                .foregroundStyle(.foregroundSecondary)
                .multilineTextAlignment(.center)

            if entryPoint.offersSettingsRoute {
                Button("action.open_settings", action: openSettings)
                    .buttonStyle(.primary())
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var message: LocalizedStringResource {
        switch entryPoint {
        case .switchedOff:
            "auto_sort.unavailable.switched_off"
        case .downloading:
            "auto_sort.unavailable.downloading"
        // Reached whenever an ineligible device arrives here, which the empty-state
        // étagère card does on purpose: it is the empty state, so it always leads into the
        // flow, and this is where the device's limitation gets said out loud. The settings
        // entry point hides itself instead, so it never renders this.
        case .hidden, .offered:
            "auto_sort.unavailable.ineligible"
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }

        openURL(url)
    }
}
