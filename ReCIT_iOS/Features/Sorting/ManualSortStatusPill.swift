//
//  ManualSortStatusPill.swift
//  ReCIT_iOS
//
//  What one étagère's header says about the pending work: « Nouvelle » for one that
//  does not exist yet, « Modifiée » for one whose contents have changed, and — for an
//  étagère nothing touches — nothing at all.
//
//  **Absence is the normal state**, which is what lets the diff be read at a glance
//  rather than counted. So the untouched case draws no pill, no placeholder and no
//  reserved width: an empty badge would be a mark of its own.
//
//  The status is never stored. It comes out of `SortWritePlan`, the same reduction the
//  recap and the write come out of, so a pill cannot promise something the apply does
//  not do — see PRD 0008.
//
//  The pill is the design system's `Tag` (`TagLabelStyle`, `23:23` in Figma), tinted
//  for « Nouvelle » and secondary for « Modifiée », per the token table in
//  docs/design-system/figma-library.md. Glyphless, hence the empty icon — the same
//  `Show glyph=false` reading `EntityMetaTagsView` makes.
//

import SwiftUI

struct ManualSortStatusPill: View {

    let status: SortWritePlan.ShelfStatus

    var body: some View {
        if let text {
            Label {
                Text(text)
            } icon: {
            }
            .labelStyle(TagLabelStyle(color: color))
        }
    }

    /// `nil` for the untouched étagère — the case that draws nothing.
    private var text: LocalizedStringKey? {
        switch status {
        case .untouched: nil
        case .new: "manual_sort.pill.new"
        case .modified: "manual_sort.pill.modified"
        }
    }

    private var color: TagLabelStyle.Color {
        switch status {
        case .new: .tinted
        case .untouched, .modified: .secondary
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: .medium) {
        ManualSortStatusPill(status: .new)
        ManualSortStatusPill(status: .modified)
        ManualSortStatusPill(status: .untouched)
    }
    .padding(.all, .medium)
}
