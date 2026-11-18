//
//  View+listMargins.swift
//  ReCIT_iOS
//
//  The per-edge list insets and margins iOS 26 brought, the unclipped scroll view an edge-to-edge
//  row can then hold, and what stands in for them before it. The app runs from iOS 18: there a
//  row's insets can only be set on all four edges at once, and a section's margins not at all,
//  so both keep the list's own and a row's scroll view keeps its clip.
//

import SwiftUI

extension View {
    /// `listRowInsets(.vertical, length)` from iOS 26. Before it the rows keep the list's
    /// insets, since setting the vertical ones alone would mean guessing the horizontal ones.
    @ViewBuilder
    func listRowVerticalInsets(_ length: CGFloat) -> some View {
        if #available(iOS 26.0, *) {
            listRowInsets(.vertical, length)
        } else {
            self
        }
    }

    /// `listSectionMargins(.horizontal, length)` from iOS 26. Before it the section keeps
    /// the list's margins.
    @ViewBuilder
    func listSectionHorizontalMargins(_ length: CGFloat) -> some View {
        if #available(iOS 26.0, *) {
            listSectionMargins(.horizontal, length)
        } else {
            self
        }
    }

    /// `scrollClipDisabled()` for a scroll view in a row of a section set edge to edge by
    /// `listSectionHorizontalMargins(0)`, so its cards run under the system column the folded
    /// iPhone Duo keeps on its right edge. From iOS 26 only: before it the section keeps its
    /// margins, which the cards must not spill into.
    @ViewBuilder
    func listRowScrollClipDisabled() -> some View {
        if #available(iOS 26.0, *) {
            scrollClipDisabled()
        } else {
            self
        }
    }
}
