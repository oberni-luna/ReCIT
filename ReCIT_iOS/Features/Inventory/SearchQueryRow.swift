//
//  SearchQueryRow.swift
//  ReCIT_iOS
//
//  A glyph and a query. It is the whole of `Search / Query Row` in the maquette, and it is
//  deliberately one view for the two things that look like it: a way on to inventaire.io here,
//  and a recent search at issue 0072. Two views would be two sets of paddings, two alignments
//  and two ways of growing under Dynamic Type, for rows that sit one above the other in the
//  same list — the difference between them is a symbol and a sentence, so that is all this view
//  takes.
//
//  The label arrives as an `AttributedString` rather than as a string plus a range to embolden:
//  a suggestion emphasises the query inside its sentence (`SearchSuggestion.label`), a recent
//  search will hand over its query plain, and neither has to explain itself to the row.
//
//  See PRD 0012.
//

import SwiftUI

struct SearchQueryRow: View {
    /// SF Symbol drawn ahead of the label: a book, a signature, a magnifier — later a clock.
    let glyph: String
    /// What the row reads, with whatever is emphasised inside it already emphasised.
    let label: AttributedString
    /// What VoiceOver says instead, when the label alone would not name the destination.
    var spokenLabel: String? = nil
    let action: () -> Void

    /// The label VoiceOver reads: the spoken one when the row carries it, the drawn one
    /// otherwise.
    private var spokenText: Text {
        if let spokenLabel {
            Text(spokenLabel)
        } else {
            Text(label)
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: .sMedium) {
                Image(systemName: glyph)
                    .imageScale(.medium)
                    .foregroundStyle(.foregroundTinted)
                    // A fixed gutter rather than the symbol's own width, so the labels of the
                    // rows line up under each other whatever glyph each one carries.
                    .frame(width: 24, alignment: .center)

                Text(label)
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundDefault)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: .zero)
            }
            .padding(.vertical, .xSmall)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(spokenText)
    }
}
