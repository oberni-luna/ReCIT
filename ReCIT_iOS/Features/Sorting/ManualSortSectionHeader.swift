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
//  The state pill (« Nouvelle » / « Modifiée ») belongs here too, but it is derived
//  from the write plan and arrives with slice 0039. Its absence is the normal state,
//  so nothing has to be left behind for it.
//
//  See PRD 0008.
//

import SwiftUI

struct ManualSortSectionHeader: View {
    let section: SortSection

    var body: some View {
        HStack(spacing: .small) {
            title
                .textStyle(.action300)
                .foregroundStyle(.foregroundDefault)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("manual_sort.section.count \(section.bookCount)")
                .textStyle(.action200)
                .foregroundStyle(.foregroundSecondary)
        }
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
