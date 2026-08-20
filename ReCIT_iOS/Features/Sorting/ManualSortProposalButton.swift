//
//  ManualSortProposalButton.swift
//  ReCIT_iOS
//
//  « Proposer un rangement » — and, when it cannot be offered, as much of the reason as
//  is worth saying.
//
//  **Availability stops being a wall and becomes a button** (PRD 0008). The rule that
//  decides which of the three reasons deserves words is unchanged — `AutoSortEntryPoint`,
//  as on the settings row and the old review screen — but it now governs this control
//  and nothing else. The rest of the surface sorts books regardless, which is what makes
//  the feature degrade on a device that cannot run the model rather than disappear.
//
//  So: an ineligible device gets no button at all, since a permanent explanation is only
//  a nag; Apple Intelligence switched off gets the reason and a route to the switch; a
//  model still downloading gets an inert button and a note that it is temporary, because
//  it will fix itself.
//
//  The entry point is derived in the caller's body from `AutoSortModel.availability`,
//  which reads an observable `SystemLanguageModel` — so switching Apple Intelligence on
//  and coming back re-renders this and the button goes live, with no relaunch and
//  nothing here to invalidate. Same lever as `AutoSortPlanView` and `ProfileView`.
//
//  **The generating state was never designed** (PRD 0008 lists it under « Still to
//  design »). It is drawn here as this control alone becoming an inert progress row,
//  with the list left exactly as it is — deliberately *not* the full-screen block the
//  opening sync uses. The two waits differ in what is on screen: the opening sync has no
//  library to show yet, whereas here the library is up, it is the thing being
//  rearranged, and the proposal is about to land on it as more changes. Hiding it would
//  hide what the wait is about.
//
//  See PRD 0008.
//

import SwiftUI

struct ManualSortProposalButton: View {

    /// What auto-sort's availability makes of this control. Derived by the caller in its
    /// body, which is what keeps it live.
    let entryPoint: AutoSortEntryPoint

    /// Whether the model is working on a proposal right now.
    let isProposing: Bool

    /// Whether a write is in flight. It disables rather than hides: what the button
    /// offers is still true, it is simply not offered while the run settles — and a
    /// proposal appended to a stack a plan was already reduced from would be work the
    /// marks say nothing about.
    let isApplying: Bool

    let onPropose: () -> Void

    @Environment(\.openURL) private var openURL

    var body: some View {
        if entryPoint.isVisible {
            VStack(spacing: .small) {
                if isProposing {
                    HStack(spacing: .small) {
                        ProgressView()

                        Text("manual_sort.proposal.generating")
                            .textStyle(.content300)
                            .foregroundStyle(.foregroundSecondary)
                    }
                } else {
                    Button("manual_sort.propose", action: onPropose)
                        .buttonStyle(.secondary())
                        .disabled(entryPoint.isEnabled == false || isApplying)
                }

                if let reason {
                    Text(reason)
                        .textStyle(.footnote200)
                        .foregroundStyle(.foregroundSecondary)
                        .multilineTextAlignment(.center)
                }

                // Only where Settings can actually help — the rule the scanner's
                // permission wall follows too. Under a downloading model it would send
                // the user to a switch that is already flipped.
                if entryPoint.offersSettingsRoute {
                    Button("action.open_settings", action: openSettings)
                        .buttonStyle(.secondary())
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    /// Said only where saying it buys the user something. A working model needs no
    /// explanation, and a device that will never run one is hidden before it gets here.
    private var reason: LocalizedStringKey? {
        switch entryPoint {
        case .switchedOff: "manual_sort.proposal.unavailable.switched_off"
        case .downloading: "manual_sort.proposal.unavailable.downloading"
        case .offered, .hidden: nil
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }

        openURL(url)
    }
}
