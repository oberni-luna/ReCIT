//
//  LensTabPicker.swift
//  ReCIT_iOS
//
//  A screen's pages named in a row of words, the selected one in a glass capsule — the tabs of
//  Messages' Contacts card, quieter than a segmented control. Used by a reader's profile
//  (`UserProfileTabPicker`) and a list's screen (`ListDetailTabPicker`), each over a `TabPager`.
//
//  **The capsule follows the pager** rather than the selection: it slides under the finger as a
//  page is swiped, between two words by as much of each page as is on screen, and glides to a word
//  chosen by its name as the pager turns to it.
//
//  **It is also a lens that can be picked up.** A touch lifts it, a little larger, the words under
//  it magnified; it follows the finger across the words; let go, it settles on the nearest word —
//  or the next one, flung — and the pager turns to it, the capsule springing a little past the
//  word before it rests. Pulled past the first or last word it follows less and less and stretches
//  towards the finger, as a scroll view's edge does, and springs back when let go.
//
//  The words are drawn twice for that (`LensTabLabels`): in grey with a hole where the capsule
//  is, and in the selected colour through the capsule only — which also has a word half dark,
//  half grey while the capsule is between two. Public API only: the refraction at the lens's
//  edge, which UIKit's private `_UILiquidLensView` draws, is not there. The geometry is
//  `LensTabTrack`'s.
//
//  **A tick each time the held capsule reaches another word**, as a segmented control's thumb
//  does: the selection haptic, under the finger and when a flick carries it one word further.
//

import SwiftUI

struct LensTabPicker<Tab: CaseIterable & Hashable, Label: View>: View {
    @Binding var selection: Tab
    /// Where the pager stands: 0 on the first tab, 1 on the second, in between during a swipe.
    let pagePosition: CGFloat
    @ViewBuilder let label: (Tab) -> Label

    /// Each word's frame in the picker, which the capsule is drawn between.
    @State private var labelFrames: [Tab: CGRect] = [:]
    @State private var size: CGSize = .zero
    /// Where the capsule stands while a finger holds it, and while it settles after: the pager's
    /// position takes over once the pager has reached it.
    @State private var dragPosition: CGFloat?
    /// How far from the capsule's centre the finger took it, kept as it moves so the capsule
    /// does not jump under the finger. `nil` when no finger is down.
    @State private var grabOffset: CGFloat?
    @State private var isLifted: Bool = false
    /// How far past the first or last word the finger has pulled the capsule, already damped.
    @State private var overshoot: CGFloat = 0
    /// The word nearest the capsule while a finger holds it, `nil` otherwise.
    @State private var heldIndex: Int?
    /// Bumped each time the held capsule reaches another word, for the selection haptic.
    @State private var feedbackTick: Int = 0
    @GestureState private var isTouching: Bool = false

    private static var coordinateSpace: String { "LensTabPicker" }
    /// How much larger the capsule grows when lifted, and how much the words under it.
    private static var liftScale: CGFloat { 1.15 }
    private static var magnification: CGFloat { 1.2 }
    private static var liftAnimation: Animation { .spring(duration: 0.35, bounce: 0.4) }
    private static var settleAnimation: Animation { .spring(duration: 0.5, bounce: 0.35) }

    private var tabs: [Tab] {
        Array(Tab.allCases)
    }

    /// The words' frames in order, once all of them are measured.
    private var track: LensTabTrack {
        let frames: [CGRect] = tabs.compactMap { labelFrames[$0] }
        return .init(frames: frames.count == tabs.count ? frames : [])
    }

    private var position: CGFloat {
        dragPosition ?? track.clamped(pagePosition)
    }

    private func nearestIndex(_ position: CGFloat) -> Int {
        Int(position.rounded())
    }

    /// Moves the held capsule's word to `index`, with a tick if it is another one.
    private func hold(_ index: Int) {
        guard index != heldIndex else { return }
        heldIndex = index
        feedbackTick += 1
    }

    var body: some View {
        let track: LensTabTrack = track
        let lens: CGRect? = track.lensFrame(
            at: position,
            scale: isLifted ? Self.liftScale : 1,
            overshoot: overshoot
        )

        LensTabLabels(
            color: .foregroundSecondary,
            measuring: (
                selection: $selection,
                coordinateSpace: Self.coordinateSpace,
                onFrame: { tab, frame in labelFrames[tab] = frame }
            ),
            label: label
        )
        .mask {
            // Holed where the capsule is: the lens's words take over there.
            Rectangle()
                .overlay(alignment: .topLeading) {
                    if let lens {
                        Capsule()
                            .frame(width: lens.width, height: lens.height)
                            .offset(x: lens.minX, y: lens.minY)
                            .blendMode(.destinationOut)
                    }
                }
                .compositingGroup()
        }
        .background(alignment: .topLeading) {
            if let lens {
                Color.clear
                    .glassCapsule()
                    .frame(width: lens.width, height: lens.height)
                    .offset(x: lens.minX, y: lens.minY)
            }
        }
        .overlay(alignment: .topLeading) {
            if let lens, size.width > 0, size.height > 0 {
                LensTabLabels(color: .foregroundDefault, label: label)
                    .scaleEffect(
                        isLifted ? Self.magnification : 1,
                        anchor: .init(x: lens.midX / size.width, y: lens.midY / size.height)
                    )
                    .mask(alignment: .topLeading) {
                        Capsule()
                            .frame(width: lens.width, height: lens.height)
                            .offset(x: lens.minX, y: lens.minY)
                    }
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
        .contentShape(.rect)
        .gesture(drag)
        .sensoryFeedback(.selection, trigger: feedbackTick)
        .onChange(of: pagePosition) { _, newValue in
            // The pager has reached where the capsule settled: it leads again.
            if grabOffset == nil, let dragPosition, abs(newValue - dragPosition) < 0.001 {
                self.dragPosition = nil
            }
        }
        .onChange(of: isTouching) { _, isTouching in
            // A touch taken away by the system rather than lifted: back where it was.
            if isTouching == false, grabOffset != nil {
                grabOffset = nil
                heldIndex = nil
                withAnimation(Self.settleAnimation) {
                    isLifted = false
                    overshoot = 0
                    dragPosition = nil
                }
            }
        }
        .coordinateSpace(.named(Self.coordinateSpace))
        .accessibilityElement(children: .contain)
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named(Self.coordinateSpace))
            .updating($isTouching) { _, isTouching, _ in
                isTouching = true
            }
            .onChanged { value in
                let track: LensTabTrack = track
                if let grabOffset {
                    let center: CGFloat = value.location.x + grabOffset
                    guard let moved = track.position(forCenter: center) else { return }
                    withAnimation(.interactiveSpring) {
                        dragPosition = moved
                        overshoot = track.overshoot(forCenter: center)
                    }
                    hold(nearestIndex(moved))
                    return
                }

                // Taken by the capsule, it stays where it is under the finger; taken by another
                // word, it comes to it.
                let start: CGFloat = value.startLocation.x
                let offset: CGFloat
                if let frame = track.capsuleFrame(at: position), frame.minX...frame.maxX ~= start {
                    offset = frame.midX - start
                } else {
                    offset = 0
                }
                grabOffset = offset
                let lifted: CGFloat = track.position(forCenter: start + offset) ?? position
                // The word the capsule stood on, so only a touch on another word ticks.
                heldIndex = nearestIndex(position)
                withAnimation(Self.liftAnimation) {
                    isLifted = true
                    dragPosition = lifted
                }
                hold(nearestIndex(lifted))
            }
            .onEnded { value in
                guard let grabOffset else { return }
                self.grabOffset = nil

                let index: Int = track.releaseIndex(
                    position: position,
                    center: value.location.x + grabOffset,
                    velocity: value.velocity.width
                )
                guard tabs.indices.contains(index) else {
                    heldIndex = nil
                    return
                }
                // Flung one word further than the finger had taken it.
                hold(index)
                heldIndex = nil
                let target: CGFloat = CGFloat(index)
                // The spring carries the finger's speed past the word before it comes back.
                withAnimation(Self.settleAnimation) {
                    isLifted = false
                    overshoot = 0
                    // Already there: the pager will not move, so it leads at once.
                    dragPosition = abs(pagePosition - target) < 0.001 ? nil : target
                }
                selection = tabs[index]
            }
    }
}
