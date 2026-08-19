//
//  ShelfRowView.swift
//  ReCIT_iOS
//
//  One étagère: the watercolour wash, the books (spines or pile), the wooden plank,
//  and the shelf name beneath.
//
//  Gesture: pressing a book starts growing it; lift early and it peeks and settles back,
//  which is how the gesture advertises itself to someone who only tapped. Hold and selection
//  mode arms (haptic, and the screen blurs around this shelf), after which sliding anywhere
//  moves the growth to the book nearest the finger and lifting opens it. Wander off the card
//  and nothing is selected, so lifting there does nothing. The shelf's own list is reached by
//  tapping its name.
//
//  The focus blur is drawn inside the card, between its background and its plank, so the
//  books and the plank stay sharp without being redrawn anywhere. See ADR 0006.
//
//  Sizing is driven entirely by the `width` passed in (the grid cell width) so the
//  view returns a deterministic size — self-measuring here caused a UICollectionView
//  update loop when hosted in a List. See ADR 0003.
//

import SwiftUI

struct ShelfRowView: View {
    let shelf: Shelf
    let width: CGFloat
    @Binding var path: NavigationPath
    /// Which étagère is focused, shared with the carousel: it freezes every scroll and paints
    /// that card above its neighbours so the blur can reach them.
    @Binding var focusedShelfId: String?

    /// The book under the finger, grown. Nil when nothing is pressed, or when the finger has
    /// wandered off the card.
    @State private var grownIndex: Int?
    /// How much it has grown: it creeps up to full size over the hold, so the growth itself
    /// shows how close selection mode is.
    @State private var growth: CGFloat = 1
    /// When the finger landed — a short press is a tap, and gets a peek instead of a plain
    /// settle so the press-to-select gesture shows itself.
    @State private var pressStarted: ContinuousClock.Instant?
    @State private var editing: Bool = false

    /// Size a book reaches once selection mode is on.
    private let fullGrowth: CGFloat = 1.5
    /// Size a tapped book bounces to before settling back — the gesture advertising itself.
    private let peekGrowth: CGFloat = 1.15
    /// A press shorter than this counts as a tap.
    private let tapWindow: Duration = .milliseconds(250)
    /// Springy on purpose: books are physical, and the overshoot makes a tap's peek read.
    private let bounce: Double = 0.35

    private var metrics: ShelfCardMetrics { .init(width: width) }
    private var books: [InventoryItem] { ShelfDrawnBooks.from(shelf.items) }
    private var layout: ShelfBooksLayout { .init(books: books, metrics: metrics) }

    /// How far the wash extends below the plank (kept small); the shelf name sits at
    /// this same distance so the wash isn't cropped.
    private let washBelow: CGFloat = 16

    /// True while this shelf is the focused one.
    private var focusing: Bool { focusedShelfId == shelf._id }

    /// How far the blur spills from the card's centre: past the card's own corners and into
    /// the neighbouring étagères.
    private var haloRadius: CGFloat { width * 0.85 }

    var body: some View {
        VStack(spacing: 0) {
            shelfStack
                .padding(.top, metrics.topRoom)
            HStack(spacing: .xSmall) {
                Button(shelf.name) { path.append(NavigationDestination.shelf(id: shelf._id)) }
                    .textStyle(.footnote200)
                    .foregroundStyle(.foregroundDefault)
                    .lineLimit(1)
                Button("Modifier l'étagère", systemImage: "pencil") { editing = true }
                    .labelStyle(.iconOnly)
                    .font(.footnote)
                    .foregroundStyle(.foregroundSecondary)
            }
            .buttonStyle(.plain)
            .padding(.top, washBelow)
        }
        .frame(width: width)
        // A firmer tick for entering selection mode than for crossing a book.
        .sensoryFeedback(trigger: focusing) { _, focusing in
            focusing ? .impact(weight: .medium) : nil
        }
        .sensoryFeedback(.selection, trigger: focusing ? grownIndex : nil)
        .sheet(isPresented: $editing) { ShelfFormView(shelf: shelf) }
    }

    private var shelfStack: some View {
        ZStack(alignment: .bottom) {
            // Wash centred vertically on the plank: constrained to a plank-height box
            // pinned to the bottom, so the (taller) blob overflows equally above the
            // books and below the shelf, with its centre on the plank.
            Image("ShelfWash")
                .resizable()
                .scaledToFit()
                .frame(width: width)
                .offset(y: washBelow)
                .opacity(0.92)
                .allowsHitTesting(false)
            VStack(spacing: 0) {
                ShelfBooksView(
                    books: books,
                    metrics: metrics,
                    layout: layout,
                    grownIndex: grownIndex,
                    growth: growth
                )
                // Books always render in FRONT of the plank so they sit on top of the
                // shelf (and a zoomed book stays above it, never behind/under).
                .zIndex(1)
                Image("ShelfPlank")
                    .resizable()
                    .scaledToFit()
                    .frame(width: width)
                    .allowsHitTesting(false)
            }
            // Blur behind the books and the plank, spilling past the card. A background, not
            // a ZStack layer: as a layer it would become the stack's tallest child and the
            // outer frame would then centre — and shift — the whole shelf.
            .background {
                ShelfFocusHaloView(radius: haloRadius)
                    .opacity(focusing ? 1 : 0)
            }
        }
        .frame(width: width, height: metrics.cardHeight)
        .overlay(alignment: .bottom) {
            ShelfPressGestureView(
                onPressBegan: startPress,
                onFocusing: focusShelf,
                onArmed: arm,
                onMoved: moveTo,
                onEnded: openGrownBook,
                onCancelled: releasePress
            )
            .frame(width: width, height: metrics.cardHeight)
        }
    }

    /// The book nearest `location` (the card's coordinates), or nil once the finger has
    /// left the étagère.
    private func book(at location: CGPoint) -> Int? {
        guard metrics.touchBox.contains(location) else { return nil }
        let point: CGPoint = .init(
            x: location.x - ShelfCardMetrics.horizontalMargin,
            y: location.y
        )
        guard let index = layout.nearestIndex(to: point), books.indices.contains(index) else { return nil }
        return index
    }

    // MARK: - Press lifecycle

    /// The touch landed: the book under it grows towards full size over the hold, so how
    /// big it is says how close selection mode is.
    private func startPress(at location: CGPoint) {
        pressStarted = .now
        grownIndex = book(at: location)
        growth = 1
        guard grownIndex != nil else { return }
        withAnimation(.spring(duration: ShelfPressRecognizer.holdDuration, bounce: bounce)) {
            growth = fullGrowth
        }
    }

    /// The hold is nearly through: blur the screen around this shelf, so the focus arrives
    /// with the book's growth instead of trailing behind it.
    private func focusShelf() {
        withAnimation(.easeInOut(duration: 0.25)) { focusedShelfId = shelf._id }
    }

    /// The hold completed: selection mode is on.
    private func arm() {
        withAnimation(.spring(duration: 0.2, bounce: bounce)) { growth = fullGrowth }
    }

    /// Selection mode: the finger moved, so the growth follows it onto another book — or
    /// off the shelf entirely, where nothing is selected.
    private func moveTo(_ location: CGPoint) {
        let index: Int? = book(at: location)
        guard index != grownIndex else { return }
        withAnimation(.spring(duration: 0.22, bounce: bounce)) { grownIndex = index }
    }

    /// The finger lifted in selection mode: open whatever it was on, if anything.
    private func openGrownBook() {
        let index: Int? = grownIndex
        releasePress()
        guard let index, books.indices.contains(index) else { return }
        path.append(NavigationDestination.book(anchor: .item(books[index])))
    }

    /// The press ended without arming. A tap gets a deliberate peek first — however brief
    /// the touch, the book visibly swells and drops back, which is how anyone discovers
    /// that holding does something.
    private func releasePress() {
        let held: Duration = pressStarted.map { ContinuousClock.now - $0 } ?? .zero
        pressStarted = nil
        withAnimation(.easeInOut(duration: 0.25)) { focusedShelfId = nil }

        guard held < tapWindow, grownIndex != nil else {
            settle()
            return
        }
        withAnimation(.spring(duration: 0.18, bounce: bounce)) {
            growth = peekGrowth
        } completion: {
            settle()
        }
    }

    /// Back to rest.
    private func settle() {
        withAnimation(.spring(duration: 0.28, bounce: bounce)) {
            growth = 1
            grownIndex = nil
        }
    }
}
