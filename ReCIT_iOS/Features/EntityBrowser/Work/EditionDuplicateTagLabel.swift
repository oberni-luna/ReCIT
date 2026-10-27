//
//  EditionDuplicateTagLabel.swift
//  ReCIT_iOS
//
//  The tag after an edition's ISBN: « Même ISBN » and « Doublon probable » tinted, with a
//  warning glyph; « Doublon signalé » secondary, with a clock — it waits on inventaire.io's
//  team, not on the reader. `Tag` in the Figma file. PRD 0028.
//

import SwiftUI

struct EditionDuplicateTagLabel: View {
    let tag: EditionDuplicateTag

    var body: some View {
        switch tag {
        case .sameIsbn:
            Label("duplicates.tag.same_isbn", systemImage: "exclamationmark.circle")
                .labelStyle(.tag)
        case .probable:
            Label("duplicates.tag.probable", systemImage: "exclamationmark.circle")
                .labelStyle(.tag)
        case .reported:
            Label("duplicates.tag.reported", systemImage: "clock")
                .labelStyle(.secondaryTag)
        }
    }
}
