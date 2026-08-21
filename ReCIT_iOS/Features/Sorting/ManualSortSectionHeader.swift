//
//  ManualSortSectionHeader.swift
//  ReCIT_iOS
//
//  The header of one band of the sorting surface: what the section is called, and how
//  many books are under it.
//
//  The count sits in the header because it is what the user judges an arrangement on,
//  and it is read off `SortSection.bookCount` — derived from the rows themselves — so
//  it cannot disagree with what is drawn below it. Pluralised by the string catalogue
//  rather than by a ternary inside an interpolation: PRD 0008 records that mistake
//  (D38) as one this screen does not repeat.
//
//  The state pill (« Nouvelle » / « Modifiée ») sits beside the name, and is derived
//  from the write plan rather than stored — so it cannot say an étagère changed while
//  the apply leaves it alone. Its absence is the normal state, and it draws nothing
//  at all in that case: see `ManualSortStatusPill`.
//
//  The apply mark leads the row, so the list reads as a checklist the moment a run
//  starts ticking it off — the same reading the review screen's header already had, and
//  the `Mark glyph` slot the design's header component carries. An étagère the run has
//  nothing to do to gets no mark at all, so there is no reserved width either: a
//  placeholder would be a mark of its own.
//
//  See PRD 0008.
//

import SwiftUI

struct ManualSortSectionHeader: View {
    let section: SortSection

    /// What this étagère's pill says, straight out of the write plan.
    let status: SortWritePlan.ShelfStatus

    /// How far the running apply has got with this étagère, or `nil` when there is no
    /// run or the run has nothing to do here.
    let mark: SortApplyLedger.ShelfOutcome?

    var body: some View {
        HStack(spacing: .small) {
            if let mark {
                ManualSortShelfMark(outcome: mark)
            }

            title
                .textStyle(.action300)
                .foregroundStyle(.foregroundDefault)
                .lineLimit(1)

            ManualSortStatusPill(status: status)

            Spacer(minLength: .zero)

            Text("manual_sort.section.count \(section.bookCount)")
                .textStyle(.action200)
                .foregroundStyle(.foregroundSecondary)
        }
        // The header sits on the page, aligned with the card's outer edge rather than with
        // the title inside it, and carries its own spacing now that the rows were
        // flattened out of `Section` (see `ManualSortRows`).
        .padding(.horizontal, .medium)
        .padding(.top, .xxSmall)
        .padding(.bottom, .small)
    }

    /// The pile has no name of its own — what it is called is copy, so it is resolved
    /// here rather than carried through the model. An étagère's name, by contrast, is
    /// user data and goes through `verbatim:`: handing it to the catalogue as a key is
    /// exactly the divergence recorded against the auto-sort screens.
    private var title: Text {
        if let name = section.name {
            Text(verbatim: name)
        } else {
            Text("manual_sort.unshelved.title")
        }
    }
}
