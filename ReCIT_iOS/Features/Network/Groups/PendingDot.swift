//
//  PendingDot.swift
//  ReCIT_iOS
//
//  The red dot after a group's name when it waits on me. Red, like the tab bar's badge it
//  accounts for — through `foregroundError`, the design system's red, rather than the system's.
//  No figure inside: the group's screen lists the requests, and the dot only has to say where.
//

import SwiftUI

struct PendingDot: View {
    let count: Int

    var body: some View {
        Circle()
            .frame(width: 10, height: 10)
            .foregroundStyle(.foregroundError)
            .accessibilityElement()
            .accessibilityLabel(Text("groups.requests.pending \(count)"))
            .accessibilityIdentifier("e2e.groups.pending")
    }
}
