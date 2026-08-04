//
//  TransactionActionsBar.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 04/08/2026.
//

import SwiftUI

/// Footer action bar for a transaction detail screen.
///
/// Left to right: a primary "default action" pill (accept / confirm / close),
/// a message button, and an overflow "…" button holding the remaining actions.
///
/// Behaviour:
/// - A default action runs immediately, showing a progress indicator in the pill.
/// - The overflow actions (reject / cancel) are definitive, so they run only after
///   the user confirms in a dialog; the progress indicator then shows in the "…"
///   button.
/// - The message button just asks its owner to present the message form.
///
/// The bar holds no business logic: it reads the available transitions off the
/// transaction and hands the chosen one to `onEvent`, which performs the work.
struct TransactionActionsBar: View {
    let transaction: UserTransaction
    let user: User
    /// Performs the chosen transition (the caller routes it through the model).
    let onEvent: (TransactionTransition) async -> Void
    /// Asks the owner to present the free-message form.
    let onMessage: () -> Void

    @State private var showOverflow: Bool = false
    /// The event currently running, if any — drives the in-button progress views
    /// and disables the bar to prevent a double submit.
    @State private var runningEvent: TransactionEvent? = nil

    private var defaultTransition: TransactionTransition? {
        transaction.defaultTransition(for: user)
    }

    private var secondaryTransitions: [TransactionTransition] {
        transaction.secondaryTransitions(for: user)
    }

    private var isRunningSecondary: Bool {
        guard let runningEvent else { return false }
        return secondaryTransitions.contains { $0.event == runningEvent }
    }

    var body: some View {
        HStack(spacing: .small) {
            if let defaultTransition {
                Button {
                    run(defaultTransition)
                } label: {
                    ZStack {
                        Text(defaultTransition.event.label)
                            .opacity(runningEvent == defaultTransition.event ? 0 : 1)
                        if runningEvent == defaultTransition.event {
                            ProgressView()
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.primary())
                .frame(maxWidth: .infinity)
                .disabled(runningEvent != nil)
            }

            Button("action.send_message", systemImage: "envelope") {
                onMessage()
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.circularIcon)
            .disabled(runningEvent != nil)

            if !secondaryTransitions.isEmpty {
                Button {
                    showOverflow = true
                } label: {
                    if isRunningSecondary {
                        ProgressView()
                    } else {
                        Label("transaction.actions.more", systemImage: "ellipsis")
                    }
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.circularIcon)
                .disabled(runningEvent != nil)
                .confirmationDialog(
                    "transaction.actions.confirm_title",
                    isPresented: $showOverflow,
                    titleVisibility: .visible
                ) {
                    ForEach(secondaryTransitions, id: \.self) { transition in
                        Button(transition.event.label, role: .destructive) {
                            run(transition)
                        }
                    }
                } message: {
                    Text("transaction.actions.destructive_warning")
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func run(_ transition: TransactionTransition) {
        guard runningEvent == nil else { return }
        runningEvent = transition.event
        Task {
            await onEvent(transition)
            runningEvent = nil
        }
    }
}
