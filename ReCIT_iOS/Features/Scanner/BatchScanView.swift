//
//  BatchScanView.swift
//  ReCIT_iOS
//
//  The scanning *mode*: the camera stays up and books accumulate. Point at a barcode, the
//  book rises from the bottom over the live feed, one tap files it, the row confirms and
//  clears, and the camera is already waiting for the next one.
//
//  It replaces the single-shot scan outright — read one code, dismiss, push the book screen.
//  That flow's one virtue, looking a book up, survives as the row's tappable text.
//
//  It carries its own `NavigationStack` because it is presented modally: that is what gives
//  it a close button and lets it push the book screen without tearing the camera down.
//
//  The camera fires for as long as a barcode is in frame; which of those sightings count is
//  `BatchScanStateMachine`'s business, not this view's. Camera permission is issue 0020;
//  failure states are issue 0019. See PRD 0005.
//

import SwiftUI
import SwiftData
import CodeScanner
// `.ean13` is an AVFoundation metadata type that CodeScanner re-exposes but does not re-export.
import AVFoundation

struct BatchScanView: View {
    @Environment(EntityModel.self) private var entityModel
    @Environment(InventoryModel.self) private var inventoryModel
    @Environment(UserModel.self) private var userModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: BatchScanViewModel = .init()
    @State private var path: NavigationPath = .init()

    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .bottom) {
                CodeScannerView(
                    codeTypes: [.ean13],
                    scanMode: .continuous,
                    // Short enough that the next book is picked up as fast as it is raised;
                    // repeats are the gate's problem, not the camera's.
                    scanInterval: 0.5,
                    // Nothing here wants the frame as an image, and capturing one per scan is
                    // the most expensive thing the package does.
                    requiresPhotoOutput: false,
                    simulatedData: "9782367935836",
                    // The tick is ours, fired when a scan is *accepted* rather than seen.
                    shouldVibrateOnSuccess: false,
                    completion: handleScan
                )
                .ignoresSafeArea()

                if viewModel.state.showsRow {
                    ScanResultRowView(
                        state: viewModel.state,
                        onOpen: openBook,
                        onAdd: addPendingBook
                    )
                    .background {
                        // Without this, light text over an arbitrary camera image is
                        // unreadable — a pale book on a pale table. It bleeds past the row on
                        // both sides so it fades out rather than ending on an edge.
                        ScanOverlayPalette.scrim
                            .padding(.vertical, -DesignSystem.Spacing.xxLarge.rawValue)
                            .allowsHitTesting(false)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.snappy, value: viewModel.state)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("action.close", systemImage: "xmark") {
                        dismiss()
                    }
                    .tint(ScanOverlayPalette.ink)
                }
            }
            .navigationDestination(for: NavigationDestination.self) { destination in
                destination.viewForDestination($path)
            }
        }
    }

    private func handleScan(result: Result<ScanResult, ScanError>) {
        // Camera failures (no access, no capable device) get a screen of their own in
        // issue 0020; until then they leave the feed as it is rather than half-explaining.
        guard case .success(let scan) = result else { return }

        viewModel.codeSeen(
            scan.string,
            entityModel: entityModel,
            modelContext: modelContext
        )
    }

    /// Pushes the book screen. The pending row is deliberately left standing, so coming back
    /// lands on the same book with its action still ready.
    private func openBook(_ book: ScannedBook) {
        guard book.uri.isEmpty == false else { return }
        path.append(NavigationDestination.book(anchor: .edition(uri: book.uri)))
    }

    private func addPendingBook() {
        viewModel.addPendingBook(
            inventoryModel: inventoryModel,
            userModel: userModel,
            modelContext: modelContext
        )
    }
}
