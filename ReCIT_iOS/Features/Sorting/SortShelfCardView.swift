//
//  SortShelfCardView.swift
//  ReCIT_iOS
//
//  One étagère on the sorting grid: its books as a pile, its name, and how many books it
//  holds. It is three things at once — something to look at, something to drop a book on
//  (slice 0047), and the way into the étagère's own screen (slice 0049).
//
//  **The count lives in the title's own text**, per the design (`160:6797`): « Science
//  fiction et fantasy · 3 ». It is the one thing the grid loses next to the list it
//  replaces, and it is what decides where a book goes — "this one already has forty".
//
//  **The pill stays.** On a grid of identical white cards nothing else says that this
//  étagère does not exist on the server yet, or that this one's contents have changed. The
//  recap gives the totals; the pill says *which*. It comes out of `SortWritePlan`, the same
//  reduction the recap and the write come from, so the three cannot contradict each other.
//
//  Every measurement is a share of the width handed in (`SortGridMetrics`), so the card
//  returns a deterministic size and never measures itself — the rule ADR 0003 arrived at
//  after a self-measuring shelf caused a `UICollectionView` update loop.
//

import SwiftUI

struct SortShelfCardView: View {
    let section: SortSection
    let status: SortWritePlan.ShelfStatus
    let width: CGFloat
    /// Whether a dragged book is hovering this card. It grows a little and takes an accent
    /// border — enough to be unmistakable under a finger, little enough not to shove its
    /// neighbours around.
    var isTargeted: Bool = false
    /// Whether the front cover hands itself over to a drag.
    var isDraggable: Bool = true
    /// Where this étagère stands in the run that is writing, or `nil` for one the plan does
    /// not touch — which draws nothing, because an étagère nobody is writing to must not look
    /// like one waiting its turn.
    var outcome: SortApplyLedger.ShelfOutcome?
    /// Whether a run is writing right now. Told apart from `outcome` because a failure's badge
    /// outlives the run while the dimming and the breathing do not.
    var isApplying: Bool = false
    /// Changes when this étagère has just received a proposal, so its covers bounce in like an
    /// étagère that has just been written. Nil for a card no proposal touched.
    var arrivalToken: String?
    /// How long this card waits before its covers start arriving, so a proposal reads left to
    /// right across the grid rather than as one jump.
    var arrivalDelay: Double = 0
    /// Takes the top book off this étagère without a drag. Nil while a run owns the stack.
    var onUnshelveTop: (() -> Void)?

    private var pile: SortPile { .init(section: section) }

    var body: some View {
        VStack(spacing: .xSmall) {
            SortPileView(
                pile: pile,
                width: width,
                isDraggable: isDraggable,
                landingToken: outcome == .landed ? "landed" : arrivalToken,
                landingDelay: outcome == .landed ? 0 : arrivalDelay
            )

            Text(title)
                .textStyle(.footnote200Bold)
                .foregroundStyle(.foregroundDefault)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.vertical, .small)
        .padding(.horizontal, .xSmall)
        .frame(width: width, height: SortGridMetrics.cardHeight)
        .background(DesignSystem.Color.backgroundDefault.color)
        .clipShape(.rect(cornerRadius: DesignSystem.CornerRadius.rounded.rawValue))
        // The card is white on white now, so its outline is what makes it a card. The accent
        // border replaces it while a book hovers rather than doubling it.
        .overlay {
            RoundedRectangle(cornerRadius: .rounded)
                .strokeBorder(
                    isTargeted
                        ? DesignSystem.Color.borderTinted.color
                        : DesignSystem.Color.borderDefault.color,
                    lineWidth: isTargeted ? 2 : 1
                )
        }
        .scaleEffect(isTargeted ? 1.03 : 1)
        .animation(.easeOut(duration: 0.15), value: isTargeted)
        // Back to full opacity the moment it lands, which is half of what says "this one is
        // done" — the other half being its covers bouncing in.
        .opacity(isDimmed ? 0.8 : 1)
        .sortBreathing(isBreathing)
        .overlay {
            if outcome == .applying {
                ProgressView()
                    .controlSize(.small)
                    .accessibilityLabel("manual_sort.mark.applying")
            }
        }
        // Top leading, opposite the pill: a failure and a pending status are different facts
        // about the same étagère and must not overlap. It stays after the run settles — the
        // footer names it, and the card is where the user goes looking.
        .overlay(alignment: .topLeading) {
            if outcome == .failed {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.foregroundError)
                    .accessibilityLabel("manual_sort.mark.failed")
                    .padding(.all, .xSmall)
            }
        }
        // Top trailing, over the card's own corner: the pill is about the card, not about
        // any one book in it, and the pile is drawn towards the middle.
        .overlay(alignment: .topTrailing) {
            ManualSortStatusPill(status: status)
                .padding(.all, .xSmall)
        }
        // The pile's lower covers say nothing a reader needs: what the étagère holds is
        // reachable by opening it, and five covers would be five stops on the way to the next
        // étagère. The label carries the name, the count and the pending status, so the pill is
        // not information reserved to sighted users.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityActions {
            if let onUnshelveTop, let top = pile.draggableBook {
                Button("manual_sort.a11y.unshelve \(top.title)", action: onUnshelveTop)
            }
        }
    }

    /// « Nom · N », plus « Nouvelle » or « Modifiée » when the étagère is on one side of the
    /// pending work.
    private var accessibilityLabel: Text {
        switch status {
        case .untouched:
            Text(title)
        case .new:
            Text(title) + Text(", ") + Text("manual_sort.pill.new")
        case .modified:
            Text(title) + Text(", ") + Text("manual_sort.pill.modified")
        }
    }

    /// Dimmed while a run is writing, unless this étagère has already landed. An étagère the
    /// plan does not touch dims too: the whole screen is busy, and only the *breathing* is
    /// reserved for the ones being written.
    private var isDimmed: Bool {
        isApplying && outcome != .landed
    }

    private var isBreathing: Bool {
        isApplying && (outcome == .pending || outcome == .applying)
    }

    /// « Nom · N », or the name alone for an étagère holding nothing: the dashed hole in its art
    /// already says it is empty, and « · 0 » next to it says it twice.
    private var title: LocalizedStringKey {
        guard section.bookCount > 0 else { return .init(section.name ?? "") }
        return "manual_sort.card.title \(section.name ?? "") \(section.bookCount)"
    }
}
