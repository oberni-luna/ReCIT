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
//  `BatchScanStateMachine`'s business, not this view's.
//
//  The camera feed is gated on permission rather than assumed: the whole screen *is* the
//  feed, so a refusal without a gate is a black screen with a floating close button. See
//  `CameraAccess` and `ScannerPermissionView`.
//
//  See PRD 0005.
//

import SwiftUI
import SwiftData
import CodeScanner
// The snack bar rides its own window above everything, which is what makes it visible from
// inside this full-screen modal; the tab's shared error channel is drawn underneath it.
import LBSnackBar
// `.ean13` is an AVFoundation metadata type that CodeScanner re-exposes but does not re-export.
import AVFoundation

struct BatchScanView: View {
    @Environment(EntityModel.self) private var entityModel
    @Environment(InventoryModel.self) private var inventoryModel
    @Environment(UserModel.self) private var userModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.snackBar) private var snackBar
    @Environment(\.scenePhase) private var scenePhase

    @State private var viewModel: BatchScanViewModel = .init()
    @State private var path: NavigationPath = .init()
    @State private var cameraAccess: CameraAccess = .current

    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .bottom) {
                // Under the feed rather than instead of it, so the moment before the prompt
                // is answered is a dark screen and not a white flash.
                ScanOverlayPalette.ground
                    .ignoresSafeArea()

                if cameraAccess.showsCameraFeed {
                    CodeScannerView(
                        codeTypes: [.ean13],
                        scanMode: .continuous,
                        // Short enough that the next book is picked up as fast as it is
                        // raised; repeats are the gate's problem, not the camera's.
                        scanInterval: 0.5,
                        // Nothing here wants the frame as an image, and capturing one per
                        // scan is the most expensive thing the package does.
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
                            // unreadable — a pale book on a pale table. It bleeds past the row
                            // on both sides so it fades out rather than ending on an edge.
                            ScanOverlayPalette.scrim
                                .padding(.vertical, -DesignSystem.Spacing.xxLarge.rawValue)
                                .allowsHitTesting(false)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                } else if cameraAccess.needsExplanation {
                    ScannerPermissionView(access: cameraAccess)
                }
            }
            .animation(.snappy, value: viewModel.state)
            .task {
                // Asked when the flow opens rather than on the first barcode: someone who
                // has already refused should meet the explanation as the screen appears, not
                // after pointing the phone at a book and waiting for nothing to happen.
                cameraAccess = await CameraAccess.request()
            }
            .onChange(of: scenePhase) { _, phase in
                // Granting access in Settings sends the app through the background on the way
                // back. Without this re-read the user would return to the same explanation
                // and have to relaunch to see the scanner they just enabled.
                guard phase == .active else { return }

                cameraAccess = .current
            }
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
        // Access can be taken away while the flow is open — revoked in Settings, or a
        // restriction arriving — in which case the package is the first to know. Re-reading
        // the status swaps the dead feed for the explanation instead of leaving a black
        // screen that no longer reacts to barcodes.
        if case .failure(.permissionDenied) = result {
            cameraAccess = .current
            return
        }

        // Any other camera failure (no capable device) leaves the feed as it is rather than
        // half-explaining something the Settings route cannot fix.
        guard case .success(let scan) = result else { return }

        viewModel.codeSeen(
            scan.string,
            entityModel: entityModel,
            userModel: userModel,
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
            modelContext: modelContext,
            onFailure: { error in
                snackBar.show { SnackBarView.error(error) }
            }
        )
    }
}
