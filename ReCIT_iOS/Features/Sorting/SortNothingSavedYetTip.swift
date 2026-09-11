//
//  SortNothingSavedYetTip.swift
//  ReCIT_iOS
//
//  SORT-2 — « Rien n'est encore enregistré ». The screen's most important decision, said to
//  the user once it concerns them: the session lives in memory and nothing leaves before
//  « Appliquer » (PRD 0009), which only matters to someone who has something to lose.
//
//  **It sends the reader to the recap rather than repeating it.** What « Appliquer » will
//  write is already written under the button, one line down; the card points at the button
//  and names that sentence, instead of adding a fourth reading of the same fact to the
//  footer (PRD 0013).
//
//  **A mute `Tip`**, exactly like `SortDragToFileTip`: one boolean parameter, set from
//  `SortTipGate`, and the single rule that reads it. The eligibility — there is at least one
//  pending change, no run is in flight, this account has not applied before — lives in the
//  pure type where it can be read in one screen.
//
//  See PRD 0013 and issue 0079.
//

import Foundation
import SwiftUI
import TipKit

struct SortNothingSavedYetTip: Tip {

    /// Whether the gate says this astuce is due. Static, because TipKit's parameters are
    /// stored per tip type and not per instance — every `SortNothingSavedYetTip()` the screen
    /// builds reads the same answer.
    @Parameter
    static var isDue: Bool = false

    /// The card's two lines, as resources rather than as literals inside `Text`, because
    /// VoiceOver's arrival announcement has to say the same words — and two spellings of the
    /// same key is how a card and its announcement come to disagree.
    static let titleKey: LocalizedStringResource = "sort.tip.nothingSaved.title"
    static let messageKey: LocalizedStringResource = "sort.tip.nothingSaved.message"

    var title: Text {
        Text(Self.titleKey)
    }

    var message: Text? {
        Text(Self.messageKey)
    }

    /// The only rule, and deliberately the only one: the gate has already weighed the stack,
    /// the run in flight and what this account has learned.
    var rules: [Rule] {
        #Rule(Self.$isDue) { $0 == true }
    }
}
