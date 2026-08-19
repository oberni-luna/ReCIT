//
//  ScannerPermissionView.swift
//  ReCIT_iOS
//
//  What stands where the camera feed would be, when there is no camera feed to stand there.
//  Without it the scanner is a black screen with a floating close button: a feature that
//  looks broken rather than one that explains itself. The single-shot scanner got away with
//  that — the user tapped Scan, saw nothing and backed out of a transient sheet. A mode the
//  user is meant to stay in cannot.
//
//  It borrows `ScanOverlayPalette` rather than the design system's appearance-aware colours,
//  for the same reason the result row does: this is the camera's ground, dark whichever
//  appearance the user runs, and text on it must not invert into black on black.
//
//  The Settings button appears only when Settings can actually help. Under `.restricted` the
//  copy says the device is locked down and stops there, rather than sending the user to a
//  switch that is not theirs to flip.
//
//  See PRD 0005, issue 0020.
//

import SwiftUI

struct ScannerPermissionView: View {
    let access: CameraAccess

    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: .large) {
            Image(systemName: "video.slash")
                .font(.largeTitle)
                .foregroundStyle(ScanOverlayPalette.tint)

            VStack(spacing: .sMedium) {
                Text("scanner.permission.title")
                    .textStyle(.title50)

                Text(message)
                    .textStyle(.content300)
            }
            .foregroundStyle(ScanOverlayPalette.ink)
            .multilineTextAlignment(.center)

            if access.isRecoverableInSettings {
                Button("action.open_settings", action: openSettings)
                    .buttonStyle(.primary())
            }
        }
        .padding(.horizontal, .large)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // The reused design-system button style reads the appearance; pinning it dark makes
        // it resolve the way the rest of the overlay does, on a ground that is dark either way.
        .environment(\.colorScheme, .dark)
    }

    private var message: LocalizedStringKey {
        access.isRecoverableInSettings
            ? "scanner.permission.denied_message"
            : "scanner.permission.restricted_message"
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }

        openURL(url)
    }
}
