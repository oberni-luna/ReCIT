//
//  InventorySyncBanner.swift
//  ReCIT_iOS
//
//  The note at the head of an inventory whose first sync is running: a title, the share
//  received, the bar, and what has arrived out of what. The books themselves fill in below it
//  as they come, which is what the last sentence promises. See docs/features/0027.
//
//  Card-free: the inventory wraps it in a card of its own, a friend's profile gives it a
//  `List` row.
//

import SwiftUI

struct InventorySyncBanner: View {
    let title: LocalizedStringKey
    let state: InventoryFirstSyncState

    private var fraction: Double? {
        guard case let .running(progress) = state else { return nil }
        return progress.fraction
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .small) {
            HStack(alignment: .firstTextBaseline, spacing: .small) {
                Text(title)
                    .textStyle(.action300)
                    .foregroundStyle(.foregroundDefault)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let fraction {
                    Text(fraction, format: .percent.precision(.fractionLength(0)))
                        .textStyle(.footnote200)
                        .foregroundStyle(.foregroundSecondary)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                } else {
                    ProgressView()
                        .controlSize(.mini)
                }
            }

            InventorySyncProgressBar(state: state)

            Group {
                if case let .running(progress) = state, let total = progress.total {
                    // The figure, then what it means on screen: the books below are the ones
                    // counted here, and more are coming.
                    Text("sync.inventory.count_arriving \(progress.received) \(total)")
                } else {
                    InventorySyncCaption(state: state)
                }
            }
            .textStyle(.footnote200)
            .foregroundStyle(.foregroundSecondary)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    List {
        InventorySyncBanner(
            title: "sync.inventory.mine.title",
            state: .running(.init(workUriItemsMap: ["wd:1": ["a", "b", "c", "d"]]))
        )
        InventorySyncBanner(title: "sync.inventory.mine.title", state: .waiting)
    }
}
