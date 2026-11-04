//
//  ListCoverFlowItem.swift
//  ReCIT_iOS
//
//  One element of a list's cover flow: a work's cover, or an author's portrait in a disc, turned
//  and pushed aside according to where it stands in the strip.
//
//  The pose is read in `visualEffect`, from the item's own frame in the strip, so it follows
//  the finger at every frame without a single state change: the scroll view moves, the geometry
//  answers, and nothing else is re-rendered. `CoverFlowGeometry` says what each distance means.
//
//  It queries its work *and* its author by uri, and draws the one its list holds. Two small
//  queries rather than a generic view: a `#Predicate` needs the concrete model type, and the
//  query that does not apply simply comes back empty.
//
//  See PRD 0029.
//

import SwiftData
import SwiftUI

struct ListCoverFlowItem: View {
    let uri: String
    let listType: EntityListType
    let geometry: CoverFlowGeometry
    let size: CGSize
    /// The visible width of the strip, whose centre is the front.
    let stripWidth: CGFloat
    let action: () -> Void

    /// The strip's own coordinate space, set on its scroll view.
    static let stripSpace: String = "listCoverFlow.strip"

    @Query private var works: [Work]
    @Query private var authors: [Author]

    init(
        uri: String,
        listType: EntityListType,
        geometry: CoverFlowGeometry,
        size: CGSize,
        stripWidth: CGFloat,
        action: @escaping () -> Void
    ) {
        self.uri = uri
        self.listType = listType
        self.geometry = geometry
        self.size = size
        self.stripWidth = stripWidth
        self.action = action
        _works = Query(filter: #Predicate<Work> { $0.uri == uri })
        _authors = Query(filter: #Predicate<Author> { $0.uri == uri })
    }

    private var entity: (any Entity)? {
        switch listType {
        case .author:
            authors.first
        case .work, .publisher:
            works.first
        }
    }

    /// A portrait is a disc, a cover a book's corners.
    private var cornerRadius: CGFloat {
        listType == .author ? size.width / 2 : DesignSystem.CornerRadius.minimal.rawValue
    }

    var body: some View {
        Button(action: action) {
            artwork
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(entity?.title ?? ""))
        // What the end-to-end scenario counts to know the list holds something.
        .accessibilityIdentifier("e2e.listItemRow")
        .visualEffect { [geometry, stripWidth] content, proxy in
            let frame: CGRect = proxy.frame(in: .named(ListCoverFlowItem.stripSpace))
            let placement: CoverFlowGeometry.Placement = geometry.placement(distance: frame.midX - stripWidth / 2)

            return content
                .scaleEffect(placement.scale)
                .rotation3DEffect(
                    .degrees(placement.angle),
                    axis: (x: 0, y: 1, z: 0),
                    perspective: 0.5
                )
                .offset(x: placement.offset)
                .brightness(-placement.shade)
        }
    }

    private var artwork: some View {
        ZStack {
            DesignSystem.Color.backgroundDisable.color

            // The title stands in for a cover inventaire.io does not have, so a book without
            // one is still a book and not a grey card.
            Text(entity?.title ?? "")
                .textStyle(.footnote200Bold)
                .foregroundStyle(.foregroundSecondary)
                .multilineTextAlignment(.center)
                .padding(.all, .small)

            if let image = entity?.image, let url = URL(string: image) {
                CachedAsyncImage(url: url) { image in
                    image
                        .resizable().scaledToFill()
                } placeholder: {
                    // Sized, unlike `EmptyView`: the loader reads the frame it fills to know which
                    // size of image to fetch, and a placeholder of no size asks for nothing.
                    Color.clear
                }
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(.rect(cornerRadius: cornerRadius))
        .shadow(.light)
    }
}
