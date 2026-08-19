//
//  ShelfSectionHeader.swift
//  ReCIT_iOS
//
//  The section headers of the shelves screen. It is a view type — not a view-returning
//  function — because the project's conventions rule against splitting sub-views into
//  functions or computed properties, and because the header now has to carry more than a
//  string: "Étagères" needs a trailing action so a shelf can be created without swiping
//  the carousel to its create card, while "Tous les livres · N" reuses the very same type
//  with no action at all. Hence the optional pair.
//
//  The action is tinted rather than secondary grey: creating an étagère from here is meant
//  to read as the primary affordance, and grey would read as decoration. It is styled in
//  place rather than through a button style — the design system's three named styles are
//  all full-width large buttons, far too heavy for a section header, and one call site does
//  not justify a new one. The vertical padding and the explicit content shape widen the 12pt
//  label's tap target to roughly 31pt — deliberately short of the 44pt platform minimum,
//  because reaching it would make this header half again as tall as the one below it for an
//  action that sits alone in its row, where a miss costs nothing. See PRD 0003 / ADR 0004.
//

import SwiftUI

struct ShelfSectionHeader: View {
    let title: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(
        title: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        HStack(spacing: .small) {
            Text(title)
                .textStyle(.action200)
                .foregroundStyle(.foregroundDefault)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let actionTitle, let action {
                // Padding and content shape sit on the label, not outside the button: only
                // the label's own shape is hit-tested, so an enlarged region added around
                // the button would look bigger without being tappable.
                Button(action: action) {
                    Label(actionTitle, systemImage: "plus")
                        .textStyle(.action200)
                        .padding(.vertical, .small)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.foregroundTinted)
            }
        }
        .padding(.horizontal, .medium)
        .padding(.bottom, .small)
    }
}
