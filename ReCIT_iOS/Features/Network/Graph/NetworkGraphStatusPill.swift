//
//  NetworkGraphStatusPill.swift
//  ReCIT_iOS
//
//  The pill at the bottom left of « Tout » (PRD 0019, Q35, Q40, Q41): the counter or
//  « Synchronisation… » in Liquid Glass — the Figma capsule (`compteur`, `521:15993`) is a stand-in
//  for it — or a glass « Réessayer » button that runs the sync again. See `NetworkGraphStatus` for
//  which.
//

import SwiftUI

struct NetworkGraphStatusPill: View {
    let status: NetworkGraphStatus
    let onRetry: () -> Void

    var body: some View {
        Group {
            switch status {
            case .counter(let counter):
                Text("network.graph.counter \(counter.friends) \(counter.groups)")
                    .modifier(NetworkGraphStatusText())
            case .syncing:
                Text("network.graph.syncing")
                    .modifier(NetworkGraphStatusText())
            case .retry:
                Button("network.graph.retry", systemImage: "arrow.clockwise", action: onRetry)
                    .textStyle(.action200)
                    .buttonStyle(.glass)
            }
        }
        .accessibilityIdentifier("e2e.network.graph.status")
    }
}

#Preview {
    VStack(alignment: .leading, spacing: .medium) {
        NetworkGraphStatusPill(status: .counter(.init(friends: 42, groups: 6))) {}
        NetworkGraphStatusPill(status: .counter(.init(friends: 1, groups: 1))) {}
        NetworkGraphStatusPill(status: .syncing) {}
        NetworkGraphStatusPill(status: .retry) {}
    }
    .padding()
    .background(.backgroundDefault)
}
