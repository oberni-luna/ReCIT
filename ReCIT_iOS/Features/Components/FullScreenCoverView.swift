//
//  FullScreenCoverView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 01/10/2026.
//

import SwiftUI

/// A book's cover alone on a dark screen, fitted to the whole of it: double-tap to fill the screen
/// and again to fit it, pinch to look closer, drag to move around a magnified cover, swipe down or
/// « Fermer » to go back.
struct FullScreenCoverView: View {
    @Environment(\.dismiss) var dismiss

    let url: URL

    @State private var zoom: CoverZoom = .init()
    @GestureState private var pinch: CGFloat = 1
    @GestureState private var pan: CGSize = .zero
    @State private var fittedSize: CGSize = .zero
    @State private var screenSize: CGSize = .zero
    /// The black behind the cover, faded in rather than there from the first frame: present at
    /// once, it was a dark card zooming out of the header around a cover not yet drawn — the
    /// flash this screen opened with.
    @State private var backdropOpacity: Double = 0

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // The cover fits the whole screen, under the Dynamic Island and the home indicator
            // too; only the button keeps to the safe area.
            zoomableCover
                .ignoresSafeArea()

            Button("Fermer", systemImage: "xmark") {
                withAnimation(.easeOut(duration: 0.2)) {
                    backdropOpacity = 0
                }
                dismiss()
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .controlSize(.large)
            .padding(.all, .medium)
        }
        .background(.black.opacity(backdropOpacity))
        // The presentation's own background stays clear, so the only black is the one above.
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
        // Dark for this screen alone. `preferredColorScheme` would carry it up to the window, and
        // a light-mode app would turn dark behind the cover for the length of the zoom — the
        // flash it opened with in light mode, and only there.
        .environment(\.colorScheme, .dark)
        .statusBarHidden()
    }

    private var zoomableCover: some View {
        let shown: CoverZoom = zoom.pinching(by: pinch).panning(by: pan)

        return cover
            .scaleEffect(shown.scale)
            .offset(shown.offset)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onGeometryChange(for: CGSize.self) { $0.size } action: { screenSize = $0 }
            .contentShape(.rect)
            .gesture(magnifyGesture)
            .simultaneousGesture(panGesture, isEnabled: zoom.isZoomed)
            .onTapGesture(count: 2) {
                withAnimation(.snappy) {
                    zoom.toggle()
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Couverture")
            .accessibilityAddTraits(.isImage)
            .accessibilityIdentifier("e2e.fullScreenCover")
    }

    private var cover: some View {
        FullScreenCoverImage(url: url) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
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
}

