//
//  SortUnshelvedPanelView.swift
//  ReCIT_iOS
//
//  The anchored foot of the sorting surface: the books that are on no étagère, then what
//  saving would do, then the three controls that do it.
//
//  **It floats over the grid rather than sitting beside it.** The étagères scroll *underneath*
//  it and dissolve into it: white at the buttons, nothing at the top edge, with a progressive
//  blur under the gradient so what shows through is legible rather than busy (`160:6659`). A
//  solid block with a hard line above it cut the grid off mid-row; a fade says "there is more
//  up there" while keeping the controls readable. It is laid on with `safeAreaInset`, which is
//  what lets the scroll view keep its content behind it.
//
//  **It does not scroll away**, and that is content rather than chrome — which is why the
//  argument PRD 0008 used against a pinned bar (a tab bar already underneath, 166 pt of
//  furniture) does not apply. Three things depend on it staying put: the drag always has a
//  source under the thumb, taking a book *off* an étagère always has a target on screen, and
//  « Appliquer » is never several screens below the work.
//
//  **One row of books, not two.** A second row costs another card's height of panel, taken
//  from the grid on every screen; the design settles for one row and lets the fourth card
//  peek, which is what says the row scrolls.
//
//  **« Livres à ranger » stays when it empties**, with its count at zero — it is the only
//  target that takes a book back out of an étagère, so removing it would kill half the
//  symmetry the gesture promises, and a count at zero is the only proof the work is done
//  (PRD 0008). What goes away is the carousel, and with it its height.
//
//  The carousel's height is reserved before the library has loaded, so nothing jumps when
//  the opening sync lands on a screen the user is already looking at.
//
//  **The drop target is the row of books, not the whole region.** « Appliquer » and the recap
//  share the panel but are not somewhere a book can be let go, and the outline that shows the
//  target says so — it stops at the rule above them.
//
//  **Two places an astuce can stand, because two things get pointed at** (PRD 0013): the card
//  about the drag goes inside the drop zone, above the first cover, and the card about
//  « Appliquer » goes over the block of controls, above the button. Both are handed in as
//  views — the panel draws books and buttons, it does not decide what the screen has to teach
//  — and both cost no height at all when nothing is owed. Neither ever lies over a control,
//  which is also what keeps the end-to-end scenario's `e2e.sort.apply` and `e2e.sortBook`
//  reachable.
//

import SwiftUI

struct SortUnshelvedPanelView<Tip: View, ApplyTip: View>: View {
    let books: [AutoSortBook]
    let metrics: SortGridMetrics
    /// Whether the opening sync is still running. The panel is drawn and inert, rather than
    /// absent: it holds the screen's shape while there is nothing to put in it.
    let isLoading: Bool
    /// Whether the panel accepts gestures. False while a run owns the stack.
    let isActive: Bool
    /// Whether a run is writing right now. The carousel dims with the grid: the whole screen
    /// is busy, and the books in here are the ones being filed away.
    let isApplying: Bool
    /// Takes a book off whatever étagère it is on. Returns whether the drop was taken.
    let onDrop: (String) -> Bool
    /// The étagères a book can be filed into without a drag.
    let filingOptions: [SortFilingOption]
    /// Files one book into one étagère, as the accessibility action offers it.
    let onFile: (String, SortSection.ID) -> Void
    let footer: SortFooter
    let actions: SortActions
    /// The astuce owed to whoever is looking at this carousel, or nothing. Handed in rather
    /// than built here: the panel draws the books, it does not decide what the screen has to
    /// teach — and a `nil` one must cost no space at all, which a passed-in view gives for
    /// free and a flag would not.
    @ViewBuilder let tip: () -> Tip
    /// The astuce owed about « Appliquer », or nothing. It stands over the block of controls
    /// rather than in the carousel, because that is what it is about — and above the button
    /// rather than on it, because a card over « Appliquer » would hide the control it is
    /// explaining, and the e2e scenario's `e2e.sort.apply` with it.
    @ViewBuilder let applyTip: () -> ApplyTip
    /// Whether that astuce is up, and therefore whether the pointer aimed at « Appliquer » is
    /// drawn above the bar. A flag beside the slot, and not a look at the slot's content,
    /// because SwiftUI cannot be asked whether a `ViewBuilder` built anything — and because
    /// the pointer is a **layout sibling** of the bar rather than part of the card: it rides
    /// the guide the bar publishes (`HorizontalAlignment.sortApply`), which a full-width card
    /// cannot do without dragging the whole column sideways.
    let isApplyTipShowing: Bool

    /// Whether a dragged book is hovering the row of books. The **whole row** is the target,
    /// header included: the order in here is arrival order, so aiming at a slot between two
    /// cards would mean nothing, and a 200 pt target is one a hand coming back from an étagère
    /// cannot miss. The controls below the rule are not part of it.
    @State private var isTargeted: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: .sMedium) {
            dropZone

            VStack(alignment: .leading, spacing: .zero) {
                // Nothing at all when no astuce is owed: an absent card and an absent pointer
                // cost no height, which is why the spacing here is zero and the recap carries
                // its own gap. With one owed, the card stands directly on its pointer and the
                // pointer directly on the bar, as the mockup has it.
                applyTip()

                VStack(alignment: .sortApply, spacing: .zero) {
                    if isApplyTipShowing {
                        TipPointerView()
                    }

                    ManualSortActionBar(actions: actions)
                }

                SortFooterView(footer: footer)
                    .padding(.top, .sMedium)
            }
            .padding(.horizontal, .medium)
            .padding(.top, .medium)
            // Half-opaque white from the rule down, over the gradient that is already there: the
            // controls and the recap are the one thing on this screen that must stay readable
            // whatever scrolls behind them.
            .background(DesignSystem.Color.backgroundDefault.color.opacity(0.5))
            // The one rule left in the region: the controls are separated from the books, not
            // the region from the grid. The grid's own edge is the gradient's business.
            //
            // `border/default` now, and black at 20 % before it. The 20 % was too dark — it
            // read as a drawn line where a shadow of one was wanted — and the reason it was
            // not a token in the first place has been fixed at the token instead:
            // `border/default` is 10 % black over whatever is behind it, so it is the same
            // hairline here, on a card, and around a dashed hole.
            .overlay(alignment: .top) {
                DesignSystem.Color.borderDefault.color
                    .frame(height: 1)
            }
        }
        .padding(.top, .medium)
        .padding(.bottom, .small)
        .frame(maxWidth: .infinity)
        // White where the controls are, nothing where the grid shows through, and a blur that
        // ramps the same way underneath it. The gradient alone left scrolled covers legible
        // enough to compete with the buttons; the blur alone left them sharp behind white text.
        .background {
            ZStack {
                // A short fade rather than one spread over the whole panel: at full span the
                // radius near the top edge is barely anything, and « Livres à ranger » sat over
                // sharp covers.
                VariableBlurView(maxRadius: 22, strongEdge: .bottom, fadeSpan: 0.45)

                LinearGradient(
                    colors: [
                        DesignSystem.Color.backgroundDefault.color.opacity(0),
                        DesignSystem.Color.backgroundDefault.color
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }

    /// The target: the header and the row of books, and nothing else. The controls under the
    /// rule are not a place a book can be let go — a drop that landed on « Appliquer » filed
    /// the book somewhere the finger was never pointing, and the outline that promised it
    /// covered half the screen's furniture.
    private var dropZone: some View {
        VStack(alignment: .leading, spacing: .sMedium) {
            ShelfSectionHeader(title: header)

            // Between the header and the covers: the card's pointer has to fall on the first
            // one, and nothing the user is about to drag — or drop onto — may be under it.
            tip()

            if isLoading {
                DesignSystem.Color.clear.color
                    .frame(height: metrics.carouselHeight)
            } else if books.isEmpty {
                Text("manual_sort.unshelved.empty")
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, .medium)
            } else {
                carousel
                    .opacity(isApplying ? 0.8 : 1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        // Drawn on the zone that takes the drop, so the outline and the target are the same
        // rectangle. It still runs to the screen's edges sideways — the row of books does —
        // and stops at the rule above the controls.
        .overlay {
            if isTargeted {
                Rectangle()
                    .strokeBorder(DesignSystem.Color.borderTinted.color, lineWidth: 2)
            }
        }
        .dropDestination(for: SortBookTransfer.self) { transfers, _ in
            guard isActive, let transfer = transfers.first else { return false }
            return onDrop(transfer.bookId)
        } isTargeted: { targeted in
            isTargeted = targeted && isActive
        }
        .onChange(of: isTargeted) { _, targeted in
            guard targeted else { return }
            Haptics.Impact.soft.play()
        }
    }

    private var carousel: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: SortGridMetrics.bookSpacing) {
                ForEach(books) { book in
                    SortBookCardView(
                        book: book,
                        width: metrics.bookColumnWidth,
                        isDraggable: isActive,
                        filingOptions: isActive ? filingOptions : [],
                        onFile: { sectionId in onFile(book.id, sectionId) }
                    )
                }
            }
            .padding(.horizontal, .medium)
        }
        .frame(height: metrics.carouselHeight)
        .scrollIndicators(.hidden)
    }

    /// « Livres à ranger · N ». The count is the section's own, so it cannot disagree with
    /// the cards under it.
    private var header: String {
        .init(localized: "manual_sort.unshelved.header \(books.count)")
    }
}
