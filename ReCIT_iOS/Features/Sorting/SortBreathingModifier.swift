//
//  SortBreathingModifier.swift
//  ReCIT_iOS
//
//  The slow swell an étagère makes while it is being written: 1,00 ↔ 1,02, 1,2 s a cycle,
//  every card in phase.
//
//  **In phase, not staggered.** A grid pulsing together reads as one system working; the same
//  cards breathing out of step read as a rendering fault.
//
//  **Only the étagères the plan writes to breathe.** An étagère the run has nothing to do to
//  must not look like one waiting its turn — the rule PRD 0008 wrote for its marks, kept here
//  in another vocabulary.
//
//  Kept under Reduce Motion, on the owner's call, with the spinner on the étagère in flight
//  carrying the same information for anyone who has turned animation down (PRD 0009).
//

import SwiftUI

extension View {

    /// Breathes while `isBreathing`, and sits still otherwise.
    func sortBreathing(_ isBreathing: Bool) -> some View {
        modifier(SortBreathingModifier(isBreathing: isBreathing))
    }
}

struct SortBreathingModifier: ViewModifier {
    let isBreathing: Bool

    /// Where in the cycle the swell currently is. Toggled once when breathing starts; the
    /// repeating animation does the rest.
    @State private var isExpanded: Bool = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isExpanded ? 1.02 : 1)
            .onChange(of: isBreathing, initial: true) { _, breathing in
                guard breathing else {
                    withAnimation(.easeOut(duration: 0.2)) { isExpanded = false }
                    return
                }
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    isExpanded = true
                }
            }
    }
}
