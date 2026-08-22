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
//  recap now, so it moved to a tap on the button — slice 0051. Until then the greyed button
//  says "not now" without saying why.
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

    var body: some View {
        if entryPoint.isVisible {
            if isProposing {
                ProgressView()
                    .frame(width: 24, height: 24)
                    .padding(.all, .medium)
                    .background(DesignSystem.Color.backgroundTinted.color)
                    .clipShape(Circle())
            } else {
                Button("manual_sort.propose", systemImage: "wand.and.sparkles", action: onPropose)
                    .labelStyle(.iconOnly)
                    .buttonStyle(.circularIcon)
                    .disabled(entryPoint.isEnabled == false || isApplying)
            }
        }
    }
}
