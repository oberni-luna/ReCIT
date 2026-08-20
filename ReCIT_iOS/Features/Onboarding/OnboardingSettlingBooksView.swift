//
//  OnboardingSettlingBooksView.swift
//  ReCIT_iOS
//
//  The books on the bilan's plank, and the way they arrive: one at a time, left to right, each
//  fading in as it comes down onto the shelf. The movement is an acknowledgement of receipt, not
//  decoration — these are the books the user has just scanned, finding their place.
//
//  **Where the covers come from.** Not out of the scanner. They are read straight from the store,
//  newest first: invariant 1 of ADR 0001 says a view renders from `@Query`, and carrying a list of
//  books out of a session that has already ended would be a second source of truth for something
//  the store already knows. The query can turn up a book filed before this session — harmless, it
//  is recent and on no étagère too, which is exactly what this plank is about.
//
//  Owner in the predicate, "on no étagère" in Swift: SwiftData cannot express an empty to-many in
//  a `#Predicate`, which is why `GenreEnrichmentModel.unshelvedWorks` reads the inventory the same
//  way.
//
//  **Why this lives here and not in `ShelfBooksView`.** That view is data-driven and redraws every
//  time the carousel scrolls; an appearance animation in it would drop the books of every étagère
//  again each time one scrolled past. The arrival belongs to the screen that means something by
//  it, so the shelf's renderer is left alone and only its *geometry* is borrowed — the books stand
//  exactly where a real étagère of the same width would stand them.
//
//  **Why the painting is `PaintedBookView` and not `ShelfSpineView`.** The spine view fetches its
//  edition's page count and writes it to the store, and page count is what a spine's thickness is
//  derived from — so a book that had already settled would be resized under the reader by its own
//  arriving data. An illustration has no business going to the network for that. The lone book
//  keeps `ShelfCoverView`, which only ever loads an image into a frame it has already claimed.
//
//  Which is the same reason a cover landing late costs nothing here: every book's frame is
//  decided before the image exists, `CachedAsyncImage` cross-fades inside it, and the arrival is
//  animated against `hasSettled` alone — a value no image load can touch.
//
//  See PRD 0007, design C2, and `grill-me/design/onboarding/motion.md` for the numbers.
//

import SwiftUI
import SwiftData

struct OnboardingSettlingBooksView: View {

    /// The user's books, newest first. Filtered down to the unshelved ones below.
    @Query private var recentBooks: [InventoryItem]

    /// The illustration's width, measured rather than assumed: every size on a shelf is derived
    /// from the card's width, and this card's width is whatever share of the screen the onboarding
    /// layout gives it. `onGeometryChange` rather than a `GeometryReader`, which would take over
    /// the layout it is only reporting on.
    @State private var width: CGFloat = 0

    /// Whether the books have been asked to arrive. Flipped exactly once, a frame after they first
    /// stand on the plank, and never unflipped — which is what makes the arrival happen once per
    /// appearance of the screen and never loop.
    @State private var hasSettled: Bool = false

    /// How many books the plank carries. Five, per the design: enough for the movement to read as
    /// "one at a time", few enough that each cover is still a cover rather than a sliver.
    private let bookLimit: Int = 5
    /// The gap between two books' arrivals. It is the stagger that says "one at a time", so it
    /// survives Reduce Motion — see `OnboardingSettlingBookView`.
    private let stagger: TimeInterval = 0.08

    init(ownerId: String) {
        _recentBooks = .init(
            filter: #Predicate { $0.ownerId == ownerId },
            sort: \.created,
            order: .reverse
        )
    }

    /// The books the plank carries: the newest of the user's own that are on no étagère.
    private var books: [InventoryItem] {
        Array(recentBooks.filter(\.shelves.isEmpty).prefix(bookLimit))
    }

    private var metrics: ShelfCardMetrics { .init(width: width) }
    private var layout: ShelfBooksLayout { .init(books: books, metrics: metrics) }

    var body: some View {
        Color.clear
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.width
            } action: { measured in
                width = measured
            }
            .overlay(alignment: .bottom) {
                // Nothing until the band has been measured wide enough to lay a book out in: a
                // book sized against a width of zero would have to be resized the moment the real
                // one arrived, which is the one thing the arrival must never do.
                if layout.width > 0, books.isEmpty == false {
                    ZStack {
                        ForEach(books.enumerated(), id: \.element.id) { index, item in
                            OnboardingSettlingBookView(
                                item: item,
                                frame: layout.bookFrame(at: index),
                                presentation: presentation(at: index),
                                leaning: layout.isLeaning(at: index),
                                hasSettled: hasSettled,
                                delay: stagger * Double(index)
                            )
                        }
                    }
                    .frame(width: layout.width, height: layout.zoneHeight)
                    // Sit the books a touch into the plank, exactly as a real étagère does.
                    .offset(y: ShelfBooksView.booksOffset)
                    .onAppear(perform: settle)
                }
            }
    }

    /// How this run dresses the book at `index` — the shelf's own answer, so the illustration
    /// shows a lone book face-on and a crowded shelf as spines and a pile, like everywhere else.
    private func presentation(at index: Int) -> ShelfFocusModel.Presentation {
        switch layout.mode {
        case .singleCover: .cover
        case .allVertical: .standing
        case .mixed(let verticalCount): index < verticalCount ? .standing : .lying
        }
    }

    /// Sets the arrival going, a frame late and once only.
    ///
    /// Deliberately a frame late, for the reason `ShelfRowView.growUp` documents: a view inserted
    /// in the same transaction as its own animation has no earlier value to travel from, so
    /// SwiftUI draws it at the target and the curve is never seen. The books have to stand there
    /// invisible and high for one frame before they are asked to come down.
    private func settle() {
        guard hasSettled == false else { return }
        Task { @MainActor in hasSettled = true }
    }
}
