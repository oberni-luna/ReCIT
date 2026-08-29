//
//  ShelfRowView.swift
//  ReCIT_iOS
//
//  One étagère: the watercolour wash, the books (spines or pile), the wooden plank,
//  and a paper label stuck onto the plank's bottom edge carrying the shelf's name.
//
//  Gesture: pressing a book starts growing it; lift early and it peeks and settles back,
//  which is how the gesture advertises itself to someone who only tapped. Hold and selection
//  mode arms (haptic, and the screen blurs around this shelf), after which sliding anywhere
//  moves the growth to the book nearest the finger and lifting opens it. Wander off the card
//  and nothing is selected, so lifting there does nothing. The shelf's own list is reached by
//  pressing its label — which, drawing above the plank, takes the narrow band it overlaps out
//  of the press gesture. Accepted: books stand above the plank. See PRD 0003.
//
//  While a press is on, the pressed book is handed to `ShelfFocusModel` and drawn again by
//  `ShelfFocusOverlayView` over the whole app. The card keeps drawing its own book underneath
//  — at rest the copy sits exactly over it — which is why this view republishes the card's
//  origin for as long as the press lasts: let the two drift apart and you see the same book
//  twice. See ADR 0006.
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

    @Environment(ShelfFocusModel.self) private var focus

    /// The book under the finger, grown. Nil when nothing is pressed, or when the finger has
    /// wandered off the card.
    @State private var grownIndex: Int?
    /// This card's frame on screen, so the overlay can place the book it redraws. Published
    /// on every layout pass, not only while pressing — otherwise the first press has none.
    /// Local state, so every visible card can keep its own without contending for one.
    @State private var cardFrame: CGRect = .zero
    /// True while the book in `focus` is this card's. Only the owner writes `focus.cardOrigin`
    /// — it is one shared slot, and every visible card publishes its frame every layout pass.
    ///
    /// It has to outlast `grownIndex`, which goes nil the moment the finger leaves the
    /// étagère while the copy is still unwinding on screen; it is cleared in exactly the two
    /// places the copy is handed back.
    @State private var ownsFocus: Bool = false
    /// When the finger landed — a short press is a tap, and gets a peek instead of a plain
    /// settle so the press-to-select gesture shows itself.
    @State private var pressStarted: ContinuousClock.Instant?

    /// Size a book reaches once selection mode is on.
    private let fullGrowth: CGFloat = 2
    /// Floor on the exit, so the very briefest tap still reads as a movement.
    private let minimumExit: TimeInterval = 0.12
    /// The book's springiness. Sprung rather than eased so a tap answers at once; an eased
    /// curve starts so slowly that a tap looked like nothing had happened.
    private let bounce: Double = 0.35
    /// The cell's own arrival and departure, softer than the book's.
    private let cellDuration: TimeInterval = 0.3
    private let cellBounce: Double = 0.2

    private var metrics: ShelfCardMetrics { .init(width: width) }
    private var books: [InventoryItem] { ShelfDrawnBooks.from(shelf.items) }
    private var layout: ShelfBooksLayout { .init(books: books, metrics: metrics) }

    /// How far the wash extends below the plank (kept small), so the wash isn't cropped.
    private let washBelow: CGFloat = 16
    /// How far the label's *top* rides up over the plank's bottom edge. Anchored from the
    /// top so a taller label simply extends further down and the inset still holds.
    private let labelOverlap: CGFloat = 14
    /// Room under the label for what it draws outside its own bounds: the shadow reaches
    /// about 5pt below it, and the tilt drops a corner a little further.
    ///
    /// This is not decoration, it is what stops the carousel clipping the paper's lower
    /// edge. A negative top padding shortens the row by exactly what it lifts, so the
    /// label's bottom always lands flush against the card's bottom — raising the overlap
    /// moves that boundary up with it and never opens a gap. Only real height does.
    private let labelBleed: CGFloat = 8

    var body: some View {
        VStack(spacing: 0) {
            shelfStack
                .padding(.top, metrics.topRoom)
            // Inside the stack rather than an overlay: the stack then reserves the label's
            // height at any Dynamic Type size, so planks stay aligned card to card and the
            // carousel's scroll view cannot clip the label's lower half. Self-measuring
            // shelf cards are what caused the collection-view update loop in ADR 0003.
            NavigationLink(value: NavigationDestination.shelf(id: shelf._id)) {
                ShelfLabelView(text: shelf.name, maxWidth: metrics.booksWidth)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("e2e.shelfLabel.\(shelf.name)")
            .padding(.top, -labelOverlap)
            .padding(.bottom, labelBleed)
            .zIndex(1)
        }
        .frame(width: width)
        // A firmer tick for entering selection mode than for crossing a book.
        .sensoryFeedback(trigger: focus.isArmed) { _, armed in
            armed ? .impact(weight: .medium) : nil
        }
        .sensoryFeedback(.selection, trigger: focus.isArmed ? grownIndex : nil)
        // Torn down mid-press — the carousel is lazy, and a hard flick can recycle this card
        // while the copy is still unwinding. Nobody would republish the origin after that, so
        // the copy would freeze and, worse, never be handed back.
        .onDisappear {
            guard ownsFocus else { return }
            ownsFocus = false
            focus.reset()
        }
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
                    layout: layout
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
        }
        .frame(width: width, height: metrics.cardHeight)
        // The overlay redraws the pressed book relative to this origin — republished for as
        // long as the press lasts, so the copy travels with the shelf when the page or the
        // carousel scrolls under it. Published only once, it hung in mid-air.
        .onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .global)
        } action: { frame in
            cardFrame = frame
            if ownsFocus { focus.cardOrigin = frame.origin }
        }
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

    /// Hands the book at `index` to the overlay, in this card's coordinates, dressed the way
    /// this shelf draws it — and, with it, where the card currently sits on screen. The
    /// overlay adds the two.
    ///
    /// Only the frame within the card is computed here, so nothing has to run again when the
    /// page scrolls: from then on the origin alone moves, and `onGeometryChange` publishes it.
    private func publish(_ index: Int?) {
        guard let index, books.indices.contains(index) else {
            focus.book = nil
            return
        }
        focus.cardOrigin = cardFrame.origin
        focus.book = .init(
            item: books[index],
            frameInCard: layout.bookFrame(at: index)
                .offsetBy(dx: ShelfCardMetrics.horizontalMargin, dy: ShelfBooksView.booksOffset),
            presentation: presentation(at: index),
            leaning: layout.isLeaning(at: index)
        )
        ownsFocus = true
    }

    private func presentation(at index: Int) -> ShelfFocusModel.Presentation {
        switch layout.mode {
        case .singleCover: .cover
        case .allVertical: .standing
        case .mixed(let verticalCount): index < verticalCount ? .standing : .lying
        }
    }

    // MARK: - Press lifecycle

    /// The touch landed: the book under it grows towards full size over the hold, so how
    /// big it is says how close selection mode is.
    private func startPress(at location: CGPoint) {
        pressStarted = .now
        grownIndex = book(at: location)
        focus.growth = 1
        focus.progress = 0
        publish(grownIndex)
        guard grownIndex != nil else { return }
        growUp()
    }

    /// Grows the copy to full size. Deliberately a frame late: a view inserted in the same
    /// transaction as its own animation has no earlier value to travel from, so SwiftUI draws
    /// it at the target — the book snapped straight to ×2 and read as a flash. Publishing
    /// first, animating next frame, is what makes the curve visible at all.
    private func growUp() {
        onNextFrame {
            withAnimation(.spring(duration: ShelfPressRecognizer.holdDuration, bounce: bounce)) {
                focus.growth = fullGrowth
            }
        }
    }

    private func onNextFrame(_ work: @escaping @MainActor () -> Void) {
        Task { @MainActor in work() }
    }

    /// Halfway through the hold: the veil starts coming in, over the rest of the hold. Any
    /// earlier and a single tap would flash the screen.
    private func focusShelf() {
        withAnimation(.easeIn(duration: ShelfPressRecognizer.holdDuration / 2)) {
            focus.progress = 1
        }
    }

    /// The hold completed: selection mode is on and the book's cell slides in above it. The
    /// book itself needs nothing here — the spring started at touch-down lands on full size at
    /// exactly this moment.
    private func arm() {
        withAnimation(.spring(duration: cellDuration, bounce: cellBounce)) { focus.isArmed = true }
    }

    /// The finger came back onto the shelf mid-press: wind selection mode up again. The copy
    /// was handed back when it left, so it is being inserted afresh — hence the same
    /// publish-then-animate order as a new press.
    private func enterFocus() {
        withAnimation(.easeIn(duration: ShelfPressRecognizer.holdDuration / 2)) {
            focus.progress = 1
        }
        growUp()
        withAnimation(.spring(duration: cellDuration, bounce: cellBounce)) { focus.isArmed = true }
    }

    /// Selection mode ends — the finger wandered off the shelf, or lifted. Unwind the way
    /// entering wound up, over `duration`: the mirror of how far the entrance actually got, so
    /// a book that had only begun to grow drops straight back instead of taking the long way.
    private func exitFocus(over duration: TimeInterval) {
        withAnimation(.easeOut(duration: duration / 2)) { focus.progress = 0 }
        withAnimation(.spring(duration: cellDuration, bounce: cellBounce)) { focus.isArmed = false }
        withAnimation(.spring(duration: duration, bounce: bounce)) {
            focus.growth = 1
        } completion: {
            // Unless the finger came back, or moved to another book, in the meantime.
            guard grownIndex == nil else { return }
            focus.book = nil
            ownsFocus = false
        }
    }

    /// Selection mode: the finger moved, so the growth follows it onto another book — or off
    /// the shelf entirely, where nothing is selected.
    private func moveTo(_ location: CGPoint) {
        let index: Int? = book(at: location)
        guard index != grownIndex else { return }
        let wasOnShelf: Bool = grownIndex != nil
        grownIndex = index

        switch (wasOnShelf, index != nil) {
        case (true, true):
            // Book to book. Deliberately unanimated: the finger is picking, and morphing one
            // book's cover and title into the next one's reads as a glitch.
            publish(index)
        case (true, false):
            // Off the shelf: nothing is selected any more, so selection mode unwinds. It was
            // fully wound up, so it unwinds over the whole hold.
            exitFocus(over: ShelfPressRecognizer.holdDuration)
        case (false, true):
            publish(index)
            enterFocus()
        case (false, false):
            break
        }
    }

    /// The finger lifted in selection mode: open whatever it was on, if anything.
    private func openGrownBook() {
        let index: Int? = grownIndex
        pressStarted = nil
        grownIndex = nil
        // Dropped outright rather than animated away: the book detail screen is about to cover
        // this one, and an overlay unwinding on top of it reads as a leftover.
        ownsFocus = false
        focus.reset()
        guard let index, books.indices.contains(index) else { return }
        path.append(NavigationDestination.book(anchor: .item(books[index])))
    }

    /// The press ended without opening anything. How long it takes to come apart depends on
    /// why it ended.
    ///
    /// A **lift** is a tap, and the exit mirrors how far the entrance got: a book that barely
    /// started growing settles back just as quickly (ADR 0006, rule 3).
    ///
    /// A **travel** is the shelf being scrolled, and the mirror is wrong there. The scroll
    /// view's own slop and this recogniser's fire at about the same instant, so the shelf
    /// starts moving exactly when the copy starts unwinding — and every millisecond of that
    /// unwind is a millisecond in which the copy and the shelf's own book can be seen apart.
    /// The origin now follows the scroll, but it follows it a frame late, which on a hard
    /// flick is a hundred points of daylight. So the copy leaves at the floor instead: the
    /// shortest exit that still reads as a movement rather than a disappearance.
    ///
    /// An interruption is treated as a travel — the touch has gone elsewhere either way.
    private func releasePress(_ reason: ShelfPressRecognizer.Cancellation) {
        let held: Duration = pressStarted.map { ContinuousClock.now - $0 } ?? .zero
        pressStarted = nil
        grownIndex = nil
        exitFocus(over: reason == .lifted ? mirroredExit(of: held) : minimumExit)
    }

    /// How long the exit should take: as long as the press lasted, capped at the hold it was
    /// heading for and floored so the briefest tap still reads as a movement.
    private func mirroredExit(of held: Duration) -> TimeInterval {
        let seconds: TimeInterval = .init(held.components.seconds)
            + .init(held.components.attoseconds) / 1e18
        return min(max(seconds, minimumExit), ShelfPressRecognizer.holdDuration)
    }
}
