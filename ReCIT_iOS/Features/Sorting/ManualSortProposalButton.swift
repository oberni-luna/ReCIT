//
//  ManualSortProposalButton.swift
//  ReCIT_iOS
//
//  « Proposer un rangement » — and, when it cannot be offered, as much of the reason as
//  is worth saying.
//
//  **Availability stops being a wall and becomes a button** (PRD 0008). The rule that
//  decides which of the three reasons deserves words is unchanged — `AutoSortEntryPoint`,
//  as on the settings row — but it now governs this control and nothing else. The rest
//  of the surface sorts books regardless, which is what makes the feature degrade on a
//  device that cannot run the model rather than disappear.
//
//  So: an ineligible device gets no button at all, since a control it can never use is
//  worse than none; Apple Intelligence switched off gets the reason and a route to the
//  switch; a model still downloading gets an inert button and a note that it is
//  temporary, because it will fix itself.
//
//  **All three reasons are said out loud here, the ineligible device included**, and that
//  is not the same rule as the settings row's. The row hides itself on such a device
//  because a permanent explanation offered unasked is a nag. This screen is where the
//  empty-shelf card leads *on every device* — that was decided in PRD 0006 and it turned
//  on the flow stating the reason (see `ShelvesContent.tapEmptyShelf` and
//  features/0005). A user who followed a note reading « Ranger mes livres » has asked the
//  question, so the answer is information rather than a nag. What the entry-point rule
//  still governs is the *control*: no button here, and no route to a Settings switch that
//  does not exist. The sentence also says the rest of the screen works, which on this
//  surface is true and is the whole reason it is not a wall.
//
//  The entry point is derived in the caller's body from `AutoSortModel.availability`,
//  which reads an observable `SystemLanguageModel` — so switching Apple Intelligence on
//  and coming back re-renders this and the button goes live, with no relaunch and
//  nothing here to invalidate. Same lever as `ProfileView`.
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
        VStack(spacing: .small) {
            // The control is the entry-point rule's business: absent where it could
            // never work, inert where the wait is temporary, live otherwise.
            if entryPoint.isVisible {
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
            }

            if let reason {
                Text(reason)
                    .textStyle(.footnote200)
                    .foregroundStyle(.foregroundSecondary)
                    .multilineTextAlignment(.center)
            }

            // Only where Settings can actually help — the rule the scanner's
            // permission wall follows too. Under a downloading model it would send
            // the user to a switch that is already flipped, and on an ineligible
            // device to one that does not exist.
            if entryPoint.offersSettingsRoute {
                Button("action.open_settings", action: openSettings)
                    .buttonStyle(.secondary())
            }
        }
        .frame(maxWidth: .infinity)
    }

    /// One sentence per reason the proposal cannot be asked for, and none when it can:
    /// a working model needs no explanation. The ineligible device is named here rather
    /// than passed over in silence, because this screen is where the empty-shelf card
    /// leads on every device and the card's whole justification is that the reason gets
    /// stated once the user arrives.
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
