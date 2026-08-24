//
//  ManualSortRecapView.swift
//  ReCIT_iOS
//
//  The pending work said once, in words, just above the buttons: how many étagères
//  would be created, how many changed, how many books filed, and how many would still
//  be on no étagère.
//
//  It says the same thing as the pills up the list because it is built from the same
//  reduction — `SortWritePlan` — and not from a second count of its own. The last of
//  the four numbers is the one the pills cannot show: what the session did *not*
//  solve.
//
//  **Only the numbers that moved.** A count of zero is dropped, so a session that
//  changed one étagère reads « 1 étagère modifiée, 3 livres rangés, 3 livres resteront
//  sans étagère. » and not « 0 étagère à créer, » first. Which clauses survive is
//  `SortWritePlan.Summary.clauses`' decision, and it is a fact about the plan rather
//  than about this view.
//
//  That is why the sentence is concatenated here instead of coming out of the catalogue
//  whole, as it used to. One entry with four substitutions cannot leave one out: a
//  `zero` plural case rendering to nothing still leaves its comma behind, and there is
//  no conditional in the format string to remove it. So the catalogue owns each clause
//  with its own plural rule, and the joining is Swift's.
//
//  **The punctuation is not copy.** `", "` and the full stop are `verbatim`: a
//  catalogue key whose whole content is a comma is a key no translator can act on.
//  The locale-correct alternative is `ListFormatStyle`, which is what the stopped
//  report uses for names — but it insists on « et » before the last item, and this
//  sentence is a comma list by design (`185:7804`).
//
//  **Three states, not two.** Nothing done at all is silence — the caller does not
//  render this view. Work that cancels itself out (a book taken off an étagère and put
//  back) has to be said out loud: the buttons still offer to save and to discard,
//  because the stack is not empty, and a recap reading « 0 étagère à créer, 0 étagère
//  modifiée » next to a live save button reads as a broken screen. So that case gets a
//  sentence of its own that explains itself. It is gated on `hasWork` rather than on
//  the clauses being empty, because a coalesced stack can still leave books unshelved
//  — one clause's worth of true sentence that would answer the wrong question.
//
//  There used to be a third line, naming the drafts left empty so they could be dropped
//  without vanishing silently. Empty drafts are created now, so there is nothing to warn
//  about — see `SortWritePlan`.
//
//  Every count is pluralised by the string catalogue, through substitutions — never by
//  a ternary inside an interpolation, which is divergence D38 and cannot enter the
//  catalogue at all. See PRD 0008.
//
//  It declares no colour, no text style and no alignment: `SortFooterView` sets those for
//  every reading of the slot at once, and a value set here would win over it.
//

import SwiftUI

struct ManualSortRecapView: View {

    let plan: SortWritePlan

    var body: some View {
        Group {
            if plan.hasWork, let sentence {
                sentence
            } else {
                Text("manual_sort.recap.nothing_to_save")
            }
        }
        .frame(maxWidth: .infinity)
    }

    /// The surviving clauses, joined into one sentence. Nil when nothing survived, which
    /// `hasWork` already rules out at the call site — stated as an optional rather than as
    /// a crash on an empty array, because the two conditions are related and not the same.
    private var sentence: Text? {
        let clauses: [SortWritePlan.Summary.Clause] = plan.summary.clauses
        guard let first = clauses.first else { return nil }
        return clauses
            .dropFirst()
            .reduce(Text(first.phrase)) { sentence, clause in
                sentence + Text(verbatim: ", ") + Text(clause.phrase)
            } + Text(verbatim: ".")
    }
}

private extension SortWritePlan.Summary.Clause {

    /// This clause's copy, count included. The key carries the number so the catalogue
    /// can pluralise it; nothing here chooses between singular and plural.
    var phrase: LocalizedStringKey {
        switch self {
        case .shelvesToCreate(let count): "manual_sort.recap.shelves_to_create \(count)"
        case .shelvesModified(let count): "manual_sort.recap.shelves_modified \(count)"
        case .booksFiled(let count): "manual_sort.recap.books_filed \(count)"
        case .booksLeftUnshelved(let count): "manual_sort.recap.books_left \(count)"
        }
    }
}
