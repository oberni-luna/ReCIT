//
//  TipCardStyle.swift
//  ReCIT_iOS
//
//  The astuce card of the mockup, as a `TipViewStyle`: the green card, its title, its
//  sentence, and the cross that puts it away (`Astuce / TipKit`, `316:8597`).
//
//  **Tokens only, no literal anything.** `background/tinted-inverse` for the card,
//  `foreground/tinted-inverse` for everything written on it, `Action/action300` for the
//  title, `Content/content300` for the text, `radius/rounded`, `Shadow/Light`. That is what
//  makes the dark mode the design never drew follow on its own, and what makes the card grow
//  with the body text instead of truncating it — every face here is a Dynamic Type face.
//
//  **The pointer is not part of it.** The card does not know what it aims at: a triangle
//  fixed to its centre would aim at neither a toolbar button nor the first book of a
//  carousel. `TipPointerView` is a separate 20 × 9 shape the screen places beside the card,
//  which is also how the Figma file has it — an instance node cannot be moved.
//
//  **Closing is handed back to the caller** rather than being `invalidate(reason: .tipClosed)`.
//  Two reasons, and both are rules of PRD 0013: the cross alone must not count as learned,
//  and what "learned" means lives per account in `TipsStore` while TipKit's own invalidation
//  is per application — so a card closed by one account would go missing for the other.
//
//  See PRD 0013 and issue 0077.
//

import SwiftUI
import TipKit

struct TipCardStyle: TipViewStyle {

    /// What the cross does. The card knows it has one; it does not know what putting it away
    /// means for the account looking at it.
    let onClose: () -> Void

    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .top, spacing: .sMedium) {
            VStack(alignment: .leading, spacing: .xSmall) {
                configuration.title
                    .textStyle(.action300)
                configuration.message
                    .textStyle(.content300)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .multilineTextAlignment(.leading)
            // One element, read in one breath: a title and its sentence are one thing to say,
            // and VoiceOver stopping between them would make the card sound like two.
            .accessibilityElement(children: .combine)

            Button("action.close", systemImage: "xmark", action: onClose)
                .labelStyle(.iconOnly)
        }
        .foregroundStyle(.foregroundTintedInverse)
        .padding(.all, .medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.Color.backgroundTintedInverse.color)
        .clipShape(.rect(cornerRadius: DesignSystem.CornerRadius.rounded.rawValue))
        .shadow(.light)
    }
}
