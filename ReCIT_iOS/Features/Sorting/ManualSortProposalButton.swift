//
//  ManualSortProposalButton.swift
//  ReCIT_iOS
//
//  « Proposer un rangement », as one round button in the action bar.
//
//  **Availability is a button, not a wall** (PRD 0008). The rule deciding which of the three
//  unavailability reasons deserves saying is unchanged — `AutoSortEntryPoint`, the same one
//  the settings row uses — but it governs this control and nothing else: the rest of the
//  surface files books on any device, which is what makes the feature degrade rather than
//  disappear.
//
//  So: an ineligible device gets **no button at all**, and the bar closes up around the two
//  that remain — a control that can never work is worse than none. Apple Intelligence
//  switched off, or a model still downloading, keeps the button and greys it.
//
//  The reason itself used to be a sentence under the button. The footer slot belongs to the
//  recap now, so it moved to **a tap on the greyed button**: the reason is still said out loud,
//  as PRD 0008 insisted — this surface is where the empty-shelf card leads on every device, so
//  a user who followed a note reading « Ranger mes livres » has asked the question — but it is
//  answered on demand rather than occupying two lines of a footer that belongs to the recap.
//  The route to the Settings switch travels with it, and only where Settings can help: under a
//  downloading model it would point at a switch that is already flipped, and on an ineligible
//  device at one that does not exist.
//
//  **The generating state is this control alone becoming a spinner**, with the library left
//  exactly where it is — deliberately not the full-screen block the opening sync uses. The
//  two waits differ in what is on screen: the opening sync has no library to show yet,
//  whereas here the library is up, it is the thing being rearranged, and the proposal is
//  about to land on it.
//
//  The entry point is derived in the caller's body from `AutoSortModel.availability`, which
//  reads an observable `SystemLanguageModel` — so switching Apple Intelligence on and coming
//  back re-renders this and the button goes live, with no relaunch.
//
//  See PRD 0008 and PRD 0009.
//

import SwiftUI

struct ManualSortProposalButton: View {

    /// What auto-sort's availability makes of this control. Derived by the caller in its
    /// body, which is what keeps it live.
    let entryPoint: AutoSortEntryPoint

    /// Whether the model is working out a proposal right now.
    let isProposing: Bool

    /// Whether a write is in flight. It disables rather than hides: what the button offers is
    /// still true, it is simply not offered while the run settles — and a proposal appended
    /// to a stack a plan was already reduced from would be work the marks say nothing about.
    let isApplying: Bool

    let onPropose: () -> Void

    @Environment(\.openURL) private var openURL

    /// Whether the reason is being shown. Only reachable on a greyed button — a working one
    /// proposes instead.
    @State private var isExplaining: Bool = false

    var body: some View {
        if entryPoint.isVisible {
            if isProposing {
                ProgressView()
                    .frame(width: 24, height: 24)
                    .padding(.all, .medium)
                    .background(DesignSystem.Color.backgroundTinted.color)
                    .clipShape(Circle())
            } else if entryPoint.isEnabled {
                Button("manual_sort.propose", systemImage: "wand.and.sparkles", action: onPropose)
                    .labelStyle(.iconOnly)
                    .buttonStyle(.circularIcon)
                    .disabled(isApplying)
            } else {
                // Inert-looking, but not dead: `.disabled` would swallow the tap, and a control
                // that swallows a tap reads as a bug rather than as a setting.
                Button("manual_sort.propose", systemImage: "wand.and.sparkles") {
                    isExplaining = true
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.circularIcon)
                .foregroundStyle(.foregroundDisable)
                .alert("manual_sort.propose", isPresented: $isExplaining) {
                    if entryPoint.offersSettingsRoute {
                        Button("action.open_settings", action: openSettings)
                    }
                    Button("action.ok", role: .cancel) { }
                } message: {
                    if let reason {
                        Text(reason)
                    }
                }
            }
        }
    }

    /// One sentence per reason the proposal cannot be asked for, and none when it can: a working
    /// model needs no explanation. The ineligible device is named rather than passed over in
    /// silence — though on that device there is no button to tap, so this is the honest answer
    /// for the two cases that keep one.
    private var reason: LocalizedStringKey? {
        switch entryPoint {
        case .switchedOff: "manual_sort.proposal.unavailable.switched_off"
        case .downloading: "manual_sort.proposal.unavailable.downloading"
        case .hidden: "manual_sort.proposal.unavailable.device"
        case .offered: nil
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }

        openURL(url)
    }
}
