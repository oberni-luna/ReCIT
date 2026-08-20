//
//  AutoSortTaxonomyDraft.swift
//  ReCIT_iOS
//
//  Phase 1's output as the model produces it: a list of étagère names and nothing
//  else. "Draft" because none of it is trusted yet — it becomes a taxonomy only
//  once the validator has canonicalised it, and only phase 1's names ever reach
//  the user. See PRD 0006.
//

import FoundationModels

@Generable(description: "Un ensemble d'étagères pour une bibliothèque personnelle.")
struct AutoSortTaxonomyDraft {

    /// The count is bounded in the *schema*, not only in the prompt. Asked in prose
    /// alone the model ignores the budget outright and returns one étagère per genre
    /// — measured, repeatedly — which is precisely the one-shelf-per-genre outcome
    /// the three-phase split exists to prevent. The tailored figure still goes in
    /// the prompt; this is the floor and ceiling underneath it, wide enough to suit
    /// any collection and narrow enough that a runaway list cannot come back.
    @Guide(description: "Les noms des étagères, du rayon le plus fourni au plus modeste.", .count(3...8))
    var etageres: [String]
}
