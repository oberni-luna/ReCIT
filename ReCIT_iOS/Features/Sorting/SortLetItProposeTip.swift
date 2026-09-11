//
//  SortLetItProposeTip.swift
//  ReCIT_iOS
//
//  SORT-3 — « Laissez proposer un rangement ». The proposal control is a wand in a circle
//  with not one word on it, and a glyph cannot say that the phone reads the titles and the
//  genres, fills the étagères, and hands back something that is still corrected before it is
//  applied. The card says both halves in one breath, because the second is what makes the
//  first askable without feeling committed (PRD 0013).
//
//  **It comes last on purpose.** The proposal is help with the gesture, not a way round it:
//  offered before the drag has been learned it would teach the user never to file anything
//  themselves. The clause lives in `SortTipGate`, with the one that keeps the card off a
//  device where the control cannot be pressed.
//
//  **A mute `Tip`**, exactly like its two siblings: one boolean parameter, set from the gate,
//  and the single rule that reads it. Eligibility belongs in the pure type, where the three
//  astuces are read side by side.
//
//  See PRD 0013 and issue 0080.
//

import Foundation
import SwiftUI
import TipKit

struct SortLetItProposeTip: Tip {

    /// Whether the gate says this astuce is due. Static, because TipKit's parameters are
    /// stored per tip type and not per instance — every `SortLetItProposeTip()` the screen
    /// builds reads the same answer.
    @Parameter
    static var isDue: Bool = false

    /// The card's two lines, as resources rather than as literals inside `Text`, because
    /// VoiceOver's arrival announcement has to say the same words — and two spellings of the
    /// same key is how a card and its announcement come to disagree.
    static let titleKey: LocalizedStringResource = "sort.tip.propose.title"
    static let messageKey: LocalizedStringResource = "sort.tip.propose.message"

    var title: Text {
        Text(Self.titleKey)
    }

    var message: Text? {
        Text(Self.messageKey)
    }

    /// The only rule, and deliberately the only one: the gate has already weighed Apple
    /// Intelligence's availability, the run in flight and what this account has learned.
    var rules: [Rule] {
        #Rule(Self.$isDue) { $0 == true }
    }
}
