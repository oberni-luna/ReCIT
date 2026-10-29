//
//  ListCoverFlowView.swift
//  ReCIT_iOS
//
//  The top half of a list's screen: its covers in a cover flow, the one facing the reader being
//  the selection.
//
//  A horizontal `ScrollView`, not a gesture of our own. Every item is laid out `pitch` wide and the
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

    @State private var stripWidth: CGFloat = 0

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
        ScrollView(.horizontal) {
            LazyHStack(spacing: .zero) {
                ForEach(Array(uris.enumerated()), id: \.element) { index, uri in
                    ListCoverFlowItem(
                        uri: uri,
                        listType: listType,
                        geometry: geometry,
                        size: coverSize
                    ) {
                        select(uri)
                    }
                    .frame(width: CoverFlowGeometry.pitch, height: coverSize.height)
                    .zIndex(-Double(abs(index - selectedIndex)))
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $selectedURI, anchor: .center)
        .scrollIndicators(.hidden)
        // The turned covers and their shadows reach past the slots they are laid out in.
        .scrollClipDisabled()
        .contentMargins(
            .horizontal,
            max((stripWidth - CoverFlowGeometry.pitch) / 2, 0),
            for: .scrollContent
        )
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { width in
            stripWidth = width
        }
        .padding(.vertical, .large)
        .sensoryFeedback(.selection, trigger: selectedURI)
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
