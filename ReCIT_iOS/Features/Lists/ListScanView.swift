//
//  ListScanView.swift
//  ReCIT_iOS
//
//  « Scanner » over a list of works: the camera, full screen, and the one book it recognised rising
//  from the bottom with a « + ». **One book at a time**: the « + » adds the edition's work to the
//  list and closes the scanner, and the list lands on it.
//
//  Two answers before that:
//
//  - **A collection** — an edition that holds several works — asks which one, with « Toutes les
//    œuvres » last.
//  - **A book the list already holds** is said in an alert rather than added: inventaire.io keeps a
//    work once per list and would ignore the request. « Le voir » closes the scanner on it,
//    « Continuer » goes back to the camera.
//
//  The camera is gated on permission and fed by the simulated barcode under the end-to-end
//  scenario, exactly as in the batch scanner (`BatchScanCameraView`), whose pieces it reuses.
//
//  See PRD 0029.
//

import AVFoundation
import CodeScanner
import SwiftData
import SwiftUI

struct ListScanView: View {
    let list: EntityList
    /// The uris the list holds, to tell a book already there before adding it.
    let existingURIs: Set<String>
    /// Adds these uris and selects the first; called just before the scanner goes.
    let onAdd: ([String]) -> Void
    /// Selects a uri the list already holds; called just before the scanner goes.
    let onShow: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Environment(EntityModel.self) private var entityModel

    @State private var viewModel: ListScanViewModel = .init()
    @State private var cameraAccess: CameraAccess = .current
    @State private var workChoice: ListWorkChoice?
    /// The uri the list already holds, while the alert says so.
    @State private var alreadyThere: String?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScanOverlayPalette.ground
                    .ignoresSafeArea()

                if cameraAccess.showsCameraFeed {
                    CodeScannerView(
                        codeTypes: [.ean13],
                        scanMode: .continuous,
                        scanInterval: 0.5,
                        requiresPhotoOutput: false,
                        simulatedData: UITestHooks.shared.currentBarcode ?? "9782367935836",
                        shouldVibrateOnSuccess: false,
                        completion: handleScan
                    )
                    .ignoresSafeArea()

                    Group {
                        if viewModel.state.showsRow {
                            ListScanResultRow(state: viewModel.state, onAdd: add)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        } else {
                            ScanHintView()
                                .transition(.opacity)
                        }
                    }
                    .background {
                        ScanOverlayPalette.scrim
                            .padding(.vertical, -DesignSystem.Spacing.xxLarge.rawValue)
                            .allowsHitTesting(false)
                    }
                } else if cameraAccess.needsExplanation {
                    ScannerPermissionView(access: cameraAccess)
                }
            }
            .animation(.snappy, value: viewModel.state)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("list.add.title \(list.name)")
                        .textStyle(.action300)
                        .foregroundStyle(ScanOverlayPalette.ink)
                        .lineLimit(1)
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("action.close", systemImage: "xmark") {
                        dismiss()
                    }
                    .tint(ScanOverlayPalette.ink)
                }
            }
            .confirmationDialog(
                Text("list.add.choose.title"),
                isPresented: isChoosing,
                titleVisibility: .visible,
                presenting: workChoice
            ) { choice in
                ForEach(choice.works) { work in
                    Button(work.title) {
                        finish([work.uri])
                    }
                }

                Button("list.add.choose.all") {
                    finish(choice.works.map(\.uri))
                }
            } message: { _ in
                Text("list.add.choose.message \(list.name)")
            }
            .alert(
                Text("list.add.duplicate.title \(list.name)"),
                isPresented: isAlreadyThere,
                presenting: alreadyThere
            ) { uri in
                Button("list.add.duplicate.show") {
                    onShow(uri)
                    dismiss()
                }

                Button("list.add.duplicate.continue", role: .cancel) {
                    viewModel.clear()
                }
            } message: { _ in
                Text("list.add.duplicate.message")
            }
        }
        .task {
            cameraAccess = await CameraAccess.request()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }

            cameraAccess = .current
        }
        // The simulated camera's page turn, as in the batch scanner: inert outside a `-uitest` run.
        .onChange(of: viewModel.state) { _, state in
            if case .notFound = state {
                UITestHooks.shared.advanceBarcode()
            }
        }
    }

    private var isChoosing: Binding<Bool> {
        .init(
            get: { workChoice != nil },
            set: { isPresented in
                if isPresented == false {
                    workChoice = nil
                }
            }
        )
    }

    private var isAlreadyThere: Binding<Bool> {
        .init(
            get: { alreadyThere != nil },
            set: { isPresented in
                if isPresented == false {
                    alreadyThere = nil
                }
            }
        )
    }

    private func handleScan(result: Result<ScanResult, ScanError>) {
        if case .failure(.permissionDenied) = result {
            cameraAccess = .current
            return
        }

        guard case .success(let scan) = result else { return }

        viewModel.codeSeen(scan.string, entityModel: entityModel, modelContext: modelContext)
    }

    /// The « + »: the work, or which of them when the book holds several.
    private func add() {
        let works: [ListWorkOption] = viewModel.works
        if works.count > 1 {
            workChoice = .init(works: works)
        } else {
            finish(works.map(\.uri))
        }
    }

    private func finish(_ uris: [String]) {
        switch ListAdditionPlan.plan(chosen: uris, existing: existingURIs) {
        case .add(let missing):
            Haptics.Notification.success.play()
            onAdd(missing)
            dismiss()
        case .alreadyInList(let uri):
            Haptics.Notification.warning.play()
            alreadyThere = uri
        case .nothing:
            break
        }
    }
}
