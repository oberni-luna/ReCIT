//
//  CoverWallView.swift
//  ReCIT_iOS
//
//  A wall of book covers, tall enough to fill whatever it is given, drifting slowly past
//  itself: odd columns down, even columns up, at speeds close enough to look like one wall and
//  different enough not to look like one sheet. A thin renderer over `CoverWallGeometry`, which
//  owns the arithmetic — tiling, the seamless loop, which cover goes in which slot — and is
//  tested there.
//
//  **The drift is read from a clock, not animated.** `TimelineView(.animation)` asks the
//  geometry where every cover is *now*; there is no animation in flight, so there is nothing to
//  restart after a return from standby, nothing to recollect after a rotation, and no
//  half-finished interpolation when the text size changes under it. Pausing the timeline
//  freezes the wall exactly where it stands, still composed.
//
//  Three things stop it, and all three are the system asking: `accessibilityReduceMotion`, the
//  low-power mode (watched live — someone plugging in a charger while the screen is open should
//  see it start), and the app leaving the foreground. A fourth is the caller's own `isMoving`,
//  for a screen that knows it is no longer the one being looked at.
//
//  Written to be reused. Its column count, its pace and its motion are parameters, because the
//  empty-inventory screen wants the same wall behind a light veil and at a standstill. What it
//  deliberately does not own is the veil: a wall is legible under a dark green sheet on the
//  welcome screen and under a pale one over an inventory, and that is the caller's call.
//
//  See PRD 0011.
//

import SwiftUI

struct CoverWallView: View {

    /// How many columns to lay the wall on.
    var columnCount: Int = CoverWallGeometry.defaultColumnCount

    /// Scales every column's speed at once. `1` is the mockup's pace; `0` is a still wall.
    var pace: CGFloat = 1

    /// Whether the caller wants the wall to drift at all. A screen that is no longer in front
    /// of anyone passes `false`.
    var isMoving: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    /// The moment this wall started. Held in state so the drift is measured from the wall's own
    /// birth rather than from an absolute date — two walls on screen would otherwise be in
    /// lockstep, and the elapsed number would grow to the size of the epoch.
    @State private var startedAt: Date = .now
    @State private var isLowPower: Bool = ProcessInfo.processInfo.isLowPowerModeEnabled

    /// Whether the wall is drifting right now. Every clause is the system or the caller saying
    /// no; there is no clause that says yes on its own.
    private var isDrifting: Bool {
        isMoving && !reduceMotion && !isLowPower && scenePhase == .active
    }

    var body: some View {
        GeometryReader { proxy in
            let geometry: CoverWallGeometry = .init(size: proxy.size, columnCount: columnCount)

            TimelineView(.animation(paused: !isDrifting)) { context in
                wall(geometry: geometry, at: context.date.timeIntervalSince(startedAt))
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
            .clipped()
        }
        // Decoration, and nothing else: it takes no touch and answers no screen reader. Thirty
        // unnamed images between the top of the screen and the first button is not a screen
        // anyone can use, and a wall that could swallow a tap would be a wall that costs
        // someone their sign-in.
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .task { await watchPowerState() }
    }

    private func wall(geometry: CoverWallGeometry, at elapsed: TimeInterval) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(0..<geometry.columnCount, id: \.self) { column in
                ForEach(0..<geometry.rowCount, id: \.self) { row in
                    cover(row: row, column: column, geometry: geometry, at: elapsed)
                }
            }
        }
    }

    /// One slot of the wall. A painted jacket for now; the covers of real books land here with
    /// issue 0070, in the same frame and at the same place.
    private func cover(
        row: Int,
        column: Int,
        geometry: CoverWallGeometry,
        at elapsed: TimeInterval
    ) -> some View {
        PaintedCoverView(
            variant: geometry.paintedIndex(
                ofRow: row,
                inColumn: column,
                variantCount: CoverWallPalette.paintedTints.count
            )
        )
        .frame(width: geometry.coverWidth, height: geometry.coverHeight)
        .shadow(color: .black.opacity(0.16), radius: 1.5, x: 0, y: 1.5)
        .offset(
            x: geometry.x(ofColumn: column),
            y: geometry.y(ofRow: row, inColumn: column, at: elapsed, speedScale: pace)
        )
    }

    /// Follows the low-power mode for as long as the wall is on screen. An async sequence
    /// rather than a Combine publisher: this project has no `ObservableObject` left and no
    /// reason to bring one back for a notification.
    private func watchPowerState() async {
        let changes = NotificationCenter.default.notifications(
            named: .NSProcessInfoPowerStateDidChange
        )

        for await _ in changes {
            isLowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
        }
    }
}

#Preview {
    CoverWallView()
        .background(.black)
}
