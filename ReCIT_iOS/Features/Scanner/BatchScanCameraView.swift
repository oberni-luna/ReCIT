//
//  BatchScanCameraView.swift
//  ReCIT_iOS
//
//  The working half of a scanning session: the live feed, and the one book rising over it that
//  is waiting to be filed. Point at a barcode, the book appears from the bottom, one tap files
//  it, the row confirms and clears, and the camera is already waiting for the next one.
//
//  A view of its own because it is the half that goes away. When a session ends having added
//  books it hands the screen to the bilan, and the camera has to be *torn down* rather than
//  covered — a capture session left running behind a full-screen summary keeps the lens and the
//  battery for nothing. Removing this view from the hierarchy is what does that, so the branch
//  that removes it lives one level up in `BatchScanView`.
//
//  The camera fires for as long as a barcode is in frame; which of those sightings count is
//  `BatchScanStateMachine`'s business, not this view's.
//
//  The feed is gated on permission rather than assumed: the whole screen *is* the feed, so a
//  refusal without a gate is a black screen with a floating close button. See `CameraAccess` and
//  `ScannerPermissionView`.
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

struct BatchScanCameraView: View {
    let viewModel: BatchScanViewModel
    /// Pushing the book screen belongs to whoever owns the navigation stack, which is not this
    /// view: the session's stack outlives the camera.
    let onOpenBook: (ScannedBook) -> Void

    @Environment(EntityModel.self) private var entityModel
    @Environment(InventoryModel.self) private var inventoryModel
    @Environment(UserModel.self) private var userModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.snackBar) private var snackBar
    @Environment(\.scenePhase) private var scenePhase

    @State private var cameraAccess: CameraAccess = .current

    var body: some View {
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
                    // On the simulator the package draws a placard instead of a feed and hands
                    // this string back on any tap. Under the end-to-end scenario that is the
                    // only camera there is, so the barcode comes from the scenario's own list;
                    // everywhere else it stays the constant it always was. See `UITestHooks`.
                    simulatedData: UITestHooks.shared.currentBarcode ?? "9782367935836",
                    // The tick is ours, fired when a scan is *accepted* rather than seen.
                    shouldVibrateOnSuccess: false,
                    completion: handleScan
                )
                .ignoresSafeArea()

                if viewModel.state.showsRow {
                    ScanResultRowView(
                        state: viewModel.state,
                        onOpen: onOpenBook,
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
        // The simulated camera's page turn: a book the session is done with — filed, unknown,
        // or already owned — is what moves the scenario on to the next barcode. Keyed on the
        // outcome rather than on the sighting, because a barcode in frame is read several times
        // a second. Inert outside a `-uitest` run. See `UITestHooks`.
        .onChange(of: viewModel.state) { _, state in
            switch state {
            case .added, .notFound, .alreadyOwned:
                UITestHooks.shared.advanceBarcode()
            case .idle, .lookingUp, .resolved, .adding:
                break
            }
        }
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
