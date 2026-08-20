//
//  SortDraftNameRule.swift
//  ReCIT_iOS
//
//  Whether a name typed into the create form may become a new étagère on the sorting
//  surface.
//
//  **The refusal happens at the form, not at apply time.** A draft named like an
//  étagère the user already has — or like another draft they made five seconds ago —
//  never reaches the change stack, so applying can never produce two étagères the user
//  reads as the same. Refusing later would mean either dropping a section the user had
//  already filled with books, or writing the duplicate and letting them find it.
//
//  The comparison is `AutoSortName`'s key — trimmed, case- and diacritic-insensitive —
//  and not a second one written here. "Romans", "romans", "ROMANS", "Rômans" and
//  " Romans " are one étagère to a reader, and the whole point of refusing is that the
//  user cannot tell two shelves apart on screen. One comparison, one meaning of "the
//  same name" across auto-sort and this surface.
//
//  It reads the **sections**, which is to say the projection: exactly the names the
//  user can see, existing étagères and drafts alike, resolved in the one place that
//  resolves them. Comparing against the snapshot and the stack separately would be two
//  readings of the same question — and the asymmetry the issue warns about (an existing
//  étagère *and* another draft) would then be two rules that could drift apart. Here it
//  is one walk over one list.
//
//  Pure by design — no store, no SwiftUI, no view state. See PRD 0008.
//

import Foundation

struct SortDraftNameRule: Equatable, Sendable {

    /// Why a name cannot become an étagère. `nil` — the absence of one of these — is
    /// the acceptance, so a caller has one thing to ask rather than two.
    enum Refusal: Equatable, Sendable {

        /// Nothing but whitespace was typed. A blank name is not a name; letting one
        /// through is how an unnamed étagère reaches a plan.
        case blank

        /// A section already reads under this name. Carries **that section's**
        /// spelling rather than what was typed: a user refused for typing "romans"
        /// has to be pointed at « Romans », which is the shelf they could not see the
        /// difference from.
        case alreadyUsed(name: String)
    }

    /// Comparison key → the name as the screen spells it. First occurrence wins, so a
    /// refusal names the section highest in the list — the same order the user read
    /// them in.
    private let namesByKey: [String: String]

    /// Built from the sections the surface is showing. The unshelved pile has no name
    /// of its own and is therefore not a name anything can collide with.
    init(sections: [SortSection]) {
        var namesByKey: [String: String] = [:]
        for section in sections {
            guard let name = section.name, let key = AutoSortName.key(name) else { continue }
            if namesByKey[key] == nil {
                namesByKey[key] = name
            }
        }
        self.namesByKey = namesByKey
    }

    /// What is wrong with this name, or `nil` when nothing is.
    func refusal(for raw: String) -> Refusal? {
        guard let key = AutoSortName.key(raw) else { return .blank }
        guard let taken = namesByKey[key] else { return nil }
        return .alreadyUsed(name: taken)
    }

    /// Whether the name may be created. The form's submit rule, and the session's
    /// guard, are the same question asked of the same value.
    func accepts(_ raw: String) -> Bool {
        refusal(for: raw) == nil
    }
}
