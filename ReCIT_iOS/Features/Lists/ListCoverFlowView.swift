//
//  ListCoverFlowView.swift
//  ReCIT_iOS
//
//  The top half of a list's screen: its covers in a cover flow, the one facing the reader being
//  the selection.
//
//  A horizontal `ScrollView`, not a gesture of our own. Every item is laid out `step` wide and the
//  scroll view snaps to them (`viewAligned`), so a swipe keeps the system's inertia and its
//  deceleration, VoiceOver can scroll it, and the vertical scroll of the screen around it is never
//  fought over. The content margins centre the first and the last item. What makes it a cover
//  flow is drawing: each item draws a full cover from its narrow slot and turns it — see
//  `ListCoverFlowItem` and `CoverFlowGeometry`.
//
//  **The selection is the scroll position, by uri.** `scrollPosition(id:anchor:)` keeps
//  `selectedURI` on the item at the centre as the strip moves, and setting it scrolls there. A uri
//  rather than the element's `_id`, because an element added optimistically changes id when the
//  server answers, and the strip must not lose the book it has just shown.
//
//  The front cover is drawn above its neighbours, and each rank above the next: `zIndex` follows
//  the distance to the selection, so the overlaps fall the way they do in the mockup.
//
//  See PRD 0029 and the `Liste détails` section of the Figma file (`843:12721`).
//

import SwiftUI

struct ListCoverFlowView: View {
    let uris: [String]
    let listType: EntityListType
    @Binding var selectedURI: String?
    let onOpen: (String) -> Void
    private var highlightedURI: String?

    /// A work's cover is the mockup's 172 × 258; an author's portrait a 200 pt disc.
    private var coverSize: CGSize {
        switch listType {
        case .author:
            .init(width: 200, height: 200)
        case .work, .publisher:
            .init(width: 172, height: 258)
        }
    }

    private var geometry: CoverFlowGeometry {
        .init(coverWidth: coverSize.width)
    }

    private var selectedIndex: Int {
        uris.firstIndex { $0 == selectedURI } ?? 0
    }

    var body: some View {
        // The strip's width is read in the layout pass that places it — a `GeometryReader`, not a
        // measure taken after: its content margins are what centre the first and last covers, and
        // in a list row a width measured after the first layout either came too late (the
        // selection off screen) or never came (no strip at all).
        GeometryReader { proxy in
            strip(width: proxy.size.width)
        }
        .frame(height: coverSize.height)
        .padding(.vertical, .large)
        // Not for the first selection, made as the list opens: a list pushed from a book screen
        // would tick on its first cover, then again on the book it arrives on.
        .sensoryFeedback(.selection, trigger: selectedURI) { oldURI, newURI in
            oldURI != nil && newURI != nil
        }
    }

    private func strip(width stripWidth: CGFloat) -> some View {
        ScrollView(.horizontal) {
            // Not lazy: a `LazyHStack` in a list row built none of its covers. A list holds tens of
            // works, not thousands, and each cover is a fixed-size frame.
            HStack(spacing: .zero) {
                ForEach(Array(uris.enumerated()), id: \.element) { index, uri in
                    ListCoverFlowItem(
                        uri: uri,
                        listType: listType,
                        geometry: geometry,
                        size: coverSize,
                        stripWidth: stripWidth
                    ) {
                        select(uri)
                    }
                    .highlighted(uri == highlightedURI)
                    .frame(width: CoverFlowGeometry.step, height: coverSize.height)
                    .zIndex(-Double(abs(index - selectedIndex)))
                }
            }
            .scrollTargetLayout()
        }
        // The space every cover measures its distance to the centre in. Named rather than
        // `.scrollView`: inside a `List`, which is a scroll view too, that one was not this strip.
        .coordinateSpace(.named(ListCoverFlowItem.stripSpace))
        // One cover per swipe: unbounded, a flick ran through half the list, and
        // even « a few » skipped three books at a time.
        .scrollTargetBehavior(.viewAligned(limitBehavior: .alwaysByOne))
        .scrollPosition(id: $selectedURI, anchor: .center)
        .scrollIndicators(.hidden)
        // The turned covers and their shadows reach past the slots they are laid out in.
        .scrollClipDisabled()
        .contentMargins(
            .horizontal,
            (stripWidth - CoverFlowGeometry.step) / 2,
            for: .scrollContent
        )
    }

    /// A cover on the side comes to the front; the one in front opens.
    private func select(_ uri: String) {
        guard uri != selectedURI else {
            onOpen(uri)
            return
        }

        withAnimation(.snappy) {
            selectedURI = uri
        }
    }
}

extension ListCoverFlowView {
    /// Rings the cover the list has just arrived on from a book screen.
    func highlighting(_ uri: String?) -> Self {
        var copy: Self = self
        copy.highlightedURI = uri
        return copy
    }
}
