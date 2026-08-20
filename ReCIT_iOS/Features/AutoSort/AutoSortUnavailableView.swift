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

    private var message: String {
        switch entryPoint {
        case .switchedOff:
            "Le rangement automatique s'appuie sur Apple Intelligence, qui est désactivé sur cet appareil. Activez-le dans les Réglages pour l'utiliser."
        case .downloading:
            "Le modèle d'Apple Intelligence est en cours de téléchargement. Le rangement automatique sera disponible sous peu."
        // Never reached from an entry point — an ineligible device is shown nothing at
        // all — but the flow can still be arrived at, and a blank screen would read as
        // a bug rather than as a device that cannot do this.
        case .hidden, .offered:
            "Le rangement automatique n'est pas disponible sur cet appareil."
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }

        openURL(url)
    }
}
