//
//  EmptyStateView.swift
//  ReCIT_iOS
//
//  The app's first reusable empty state: a glyph, a title, a sentence and an action, of which
//  only the title is compulsory. It is `Empty State` (`204:263`, `Layout=Centered`) from the
//  « États vides » pass of 2026-08-28 — see `docs/design-system/figma-library.md`.
//
//  It exists because there was nothing to reuse. Four screens draw their own centred `Text`
//  today — `ShelvesContent`, `InventoryListContent`, `EntityListView` and `EntityListDetail` —
//  and no two of them agree on the weight, the colour or the alignment (divergence D50). Each
//  new absence was a fifth variation of the same block; this is the block, written once, so the
//  next one is a call rather than a copy.
//
//  Everything the block draws comes from a token: `textStyle`, `foregroundStyle`, `Spacing`.
//  No literal size, colour or padding, which is also what makes it read in light and in dark
//  without a second set of values, and grow with Dynamic Type without a fixed frame to fight.
//
//  **It does not place itself.** No `maxHeight`, no `Spacer`, no assumption about what sits
//  above or below: it is exactly as tall as what it holds, and the screen mounting it decides
//  where that goes. The search surface centres it in the band the keyboard leaves visible,
//  which is not the centre of the frame — see `InventorySearchContent`.
//
//  See issue 0073 and PRD 0012.
//

import SwiftUI

struct EmptyStateView: View {
    /// SF Symbol above the title, or `nil` for a block that is only words.
    var glyph: String? = nil
    /// The one thing every empty state has to say — what is not there.
    let title: LocalizedStringKey
    /// A sentence under the title, usually what would fill the emptiness. Silent when `nil`.
    var message: LocalizedStringKey? = nil
    /// The way out, when there is one to offer. Silent when `nil`.
    var action: Action? = nil

    var body: some View {
        VStack(spacing: .medium) {
            if let glyph {
                Image(systemName: glyph)
                    // The glyph carries no information the title does not: VoiceOver reads the
                    // sentence, not the picture of a magnifier.
                    .accessibilityHidden(true)
                    .textStyle(.title200)
                    .foregroundStyle(.foregroundSecondary)
            }

            VStack(spacing: .small) {
                Text(title)
                    .textStyle(.title50)
                    .foregroundStyle(.foregroundDefault)

                if let message {
                    Text(message)
                        .textStyle(.content300)
                        .foregroundStyle(.foregroundSecondary)
                }
            }
            .multilineTextAlignment(.center)
            // Long titles wrap rather than shrink: at the largest Dynamic Type sizes a
            // truncated empty state says even less than an empty screen.
            .fixedSize(horizontal: false, vertical: true)

            if let action {
                Button(action.title, action: action.handler)
                    .buttonStyle(.primary())
            }
        }
        .padding(.horizontal, .large)
        .frame(maxWidth: .infinity)
    }
}

extension EmptyStateView {
    /// The optional way out of an empty screen: what the button says, and what it does.
    ///
    /// One value rather than two loose parameters, so a label cannot arrive without the
    /// handler that makes it do something.
    struct Action {
        let title: LocalizedStringKey
        let handler: () -> Void

        init(
            title: LocalizedStringKey,
            handler: @escaping () -> Void
        ) {
            self.title = title
            self.handler = handler
        }
    }
}

#Preview("Complet") {
    EmptyStateView(
        glyph: "magnifyingglass",
        title: "inventory.search.recents.empty.title",
        message: "inventory.search.recents.empty.message",
        action: .init(title: "inventory.search.recents.clear") {}
    )
}

#Preview("Titre seul") {
    EmptyStateView(title: "inventory.search.recents.empty.title")
}
