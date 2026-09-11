//
//  SortDragToFileTip.swift
//  ReCIT_iOS
//
//  SORT-1 — « Glissez pour ranger ». The astuce that says the one gesture the whole screen
//  is made of, and says its inverse in the same breath, so a first drop can be risked
//  without fearing it (PRD 0013).
//
//  **A mute `Tip`.** Its only rule is a single boolean parameter, and that parameter is set
//  from `SortTipGate` — the eligibility lives in the pure type, where it can be read in one
//  screen, rather than being scattered across TipKit event rules in three files. TipKit is
//  left with what it is good at: ordering the group, and never showing two cards at once.
//
//  **Its parameter is not its memory.** What counts as learned is `TipsStore`'s, per account;
//  the parameter is derived from it at every render. TipKit's own datastore is per
//  application and has no idea who is signed in, so a tip invalidated through it would go
//  missing for the second account on the same phone.
//
//  See PRD 0013 and issue 0077.
//

import Foundation
import SwiftUI
import TipKit

struct SortDragToFileTip: Tip {

    /// Whether the gate says this astuce is due. Static, because TipKit's parameters are
    /// stored per tip type and not per instance — every `SortDragToFileTip()` the screen
    /// builds reads the same answer.
    @Parameter
    static var isDue: Bool = false

    /// The card's two lines, as resources rather than as literals inside `Text`, because
    /// VoiceOver's arrival announcement has to say the same words — and two spellings of the
    /// same key is how a card and its announcement come to disagree.
    static let titleKey: LocalizedStringResource = "sort.tip.drag.title"
    static let messageKey: LocalizedStringResource = "sort.tip.drag.message"

    var title: Text {
        Text(Self.titleKey)
    }

    var message: Text? {
        Text(Self.messageKey)
    }

    /// The only rule, and deliberately the only one: the gate has already weighed the
    /// carousel, the run in flight and what this account has learned.
    var rules: [Rule] {
        #Rule(Self.$isDue) { $0 == true }
    }
}
