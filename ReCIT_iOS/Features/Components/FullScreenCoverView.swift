//
//  FullScreenCoverView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 01/10/2026.
//

import SwiftUI

/// A picture — a book's cover, a reader's, a group's or an author's photo — alone over the
/// screen it opened from, blurred behind the Regular material, fitted to the whole of it:
/// double-tap to fill the screen and again to fit it, pinch to look closer, drag to move around
/// a magnified picture, swipe down or « Fermer » to go back.
struct FullScreenCoverView: View {
    private static let swipeDownDistanceToClose: CGFloat = 120

    @Environment(\.dismiss) var dismiss

    let url: URL
    private var closesOnSwipeDown: Bool = false

    @State private var zoom: CoverZoom = .init()
    @GestureState private var pinch: CGFloat = 1
    @GestureState private var pan: CGSize = .zero
    @State private var fittedSize: CGSize = .zero
    @State private var screenSize: CGSize = .zero
    /// The material behind the cover, faded in rather than there from the first frame: present at
    /// once, it was a card zooming out of the header around a cover not yet drawn — the flash
    /// this screen opened with.
    @State private var backdropOpacity: Double = 0
    @State private var swipeDownOffset: CGFloat = 0

    init(url: URL) {
        self.url = url
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // The cover fits the whole screen, under the Dynamic Island and the home indicator
            // too; only the button keeps to the safe area.
            zoomableCover
                .ignoresSafeArea()

            Button("action.close", systemImage: "xmark") {
                close()
            }
            .labelStyle(.iconOnly)
            .glassButtonStyle()
            .buttonBorderShape(.circle)
            .controlSize(.large)
            .padding(.all, .medium)
        }
        .background {
            Rectangle()
                .fill(.regularMaterial)
                .opacity(backdropOpacity)
                .ignoresSafeArea()
        }
        // The presentation's own background stays clear, so the screen underneath shows through
        // the material above, blurred.
        .presentationBackground(.clear)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                backdropOpacity = 1
            }
        }
        .onChange(of: fittedSize) { measure() }
        .onChange(of: screenSize) { measure() }
        // Swiping down to close would fight the drag that moves a magnified cover.
        .interactiveDismissDisabled(zoom.isZoomed)
        .statusBarHidden()
    }

    private var zoomableCover: some View {
        let shown: CoverZoom = zoom.pinching(by: pinch).panning(by: pan)

        return cover
            .scaleEffect(shown.scale)
            .offset(shown.offset)
            .offset(y: swipeDownOffset)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onGeometryChange(for: CGSize.self) { $0.size } action: { screenSize = $0 }
            .contentShape(.rect)
            .gesture(magnifyGesture)
            .simultaneousGesture(panGesture, isEnabled: zoom.isZoomed)
            .simultaneousGesture(swipeDownGesture, isEnabled: closesOnSwipeDown && zoom.isZoomed == false)
            .onTapGesture(count: 2) {
                withAnimation(.snappy) {
                    zoom.toggle()
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("cover.accessibility_label")
            .accessibilityAddTraits(.isImage)
            .accessibilityIdentifier("e2e.fullScreenCover")
    }

    private var cover: some View {
        FullScreenCoverImage(url: url) { image in
            image
                .resizable().scaledToFit()
                // Measured before `scaleEffect`, which leaves layout alone: this is the fitted
                // size whatever the current zoom.
                .onGeometryChange(for: CGSize.self) { $0.size } action: { fittedSize = $0 }
        }
    }

    private func measure() {
        zoom.measure(
            fitted: fittedSize,
            in: screenSize
        )
    }

    private var magnifyGesture: some Gesture {
        MagnifyGesture()
            .updating($pinch) { value, state, _ in
                state = value.magnification
            }
            .onEnded { value in
                withAnimation(.snappy) {
                    zoom.endPinch(by: value.magnification)
                }
            }
    }

    private var panGesture: some Gesture {
        DragGesture()
            .updating($pan) { value, state, _ in
                state = value.translation
            }
            .onEnded { value in
                zoom.endPan(by: value.translation)
            }
    }

    private var swipeDownGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                swipeDownOffset = pinch == 1 ? max(0, value.translation.height) : 0
            }
            .onEnded { value in
                if swipeDownOffset > 0, value.predictedEndTranslation.height > Self.swipeDownDistanceToClose {
                    close()
                } else {
                    withAnimation(.snappy) {
                        swipeDownOffset = 0
                    }
                }
            }
    }

    private func close() {
        withAnimation(.easeOut(duration: 0.2)) {
            backdropOpacity = 0
        }
        dismiss()
    }
}

extension FullScreenCoverView {
    /// Closes on a swipe down of the picture, unless it is magnified. A presentation that zooms
    /// out of its source has that gesture already, and does without this one.
    func closingOnSwipeDown() -> Self {
        var copy: Self = self
        copy.closesOnSwipeDown = true
        return copy
    }
}
