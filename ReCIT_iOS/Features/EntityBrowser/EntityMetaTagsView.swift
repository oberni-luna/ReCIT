//
//  EntityMetaTagsView.swift
//  ReCIT_iOS
//
//  The `meta` frame of the Figma `Row / Summary` component (`38:201`): a line of tinted pills
//  under the summary body, 8pt apart, glyphless.
//
//  Deliberately a row of plain strings rather than a genre-aware view. The Figma component calls
//  them meta tags and says nothing about what they mean; the book screen happens to fill them
//  with a work's genres (issue 0035), and keeping the view ignorant of that is what lets the
//  next caller put something else there without a second component.
//
//  The tag itself is `TagLabelStyle`, applied as `.labelStyle(.tag)` — the style *is* the Figma
//  `Tag` component. Note it is not `TagView`, whose background shape has no `.fill` and so
//  paints in the inherited foreground colour (divergence D8 in the Figma library doc).
//
//  Display only: no tap target, by design. Filtering the inventory by genre is out of scope.
//

import SwiftUI

struct EntityMetaTagsView: View {

    let tags: [String]

    var body: some View {
        WrappingHStack(
            horizontalSpacing: .small,
            verticalSpacing: .small
        ) {
            ForEach(tags, id: \.self) { tag in
                // `Color=Tinted`, `Show glyph=false` in the component — hence the empty icon.
                Label {
                    Text(tag)
                } icon: {
                }
                .labelStyle(.tag)
            }
        }
        // A container rather than one combined element, so VoiceOver names the group and still
        // lets each tag be read on its own. Sighted users get the same context from the pills'
        // shape; blind users would otherwise get a bare list of words after the summary.
        .accessibilityElement(children: .contain)
        .accessibilityLabel("entity.summary.tags")
    }
}

#Preview {
    VStack(alignment: .leading, spacing: .large) {
        EntityMetaTagsView(tags: ["Science-fiction", "Romans"])

        EntityMetaTagsView(
            tags: [
                "Science-fiction",
                "Romans",
                "Littérature post-apocalyptique",
                "Bande dessinée",
                "Essai",
                "Poésie",
                "Policier"
            ]
        )
    }
    .padding(.all, .medium)
}
