//
//  BatchScanViewModel.swift
//  ReCIT_iOS
//
//  Drives the batch scanner: turns barcodes into lookups, lookups into rows, and taps into
//  inventory items. Every decision about *whether* something happens belongs to
//  `BatchScanStateMachine`; this type only performs the work each accepted event implies,
//  which is why the camera package never reaches past the view.
//
//  **The add waits for the server instead of being optimistic — a deliberate departure from
//  ADR 0001.** Everywhere else in the app a write lands locally at once and reconciles in the
//  background. Here the confirmation *is* the feature: in a batch rhythm an optimistic add
//  that failed would be discovered twenty books later, with no way to tell which ones landed.
//  So the loader spins until the item exists on inventaire, and only then does the row
//  confirm and clear. See PRD 0005.
//

import Foundation
import SwiftData

@MainActor
@Observable
final class BatchScanViewModel {
    /// How long the confirmation is held before the row hands the screen back. Long enough
    /// to be seen while looking at the shelf rather than the phone, short enough not to be
    /// in the way of the next book.
    private static let confirmationDuration: Duration = .milliseconds(900)

    private var machine: BatchScanStateMachine = .init()

    @ObservationIgnored private var lookupTask: Task<Void, Never>?
    @ObservationIgnored private var addTask: Task<Void, Never>?

    var state: BatchScanState {
        machine.state
    }

    // MARK: - Camera

    /// A barcode is in frame. Called for every frame the camera resolves one, so most calls
    /// are expected to be refused by the gate.
    func codeSeen(
        _ code: String,
        entityModel: EntityModel,
        modelContext: ModelContext
    ) {
        guard code.count == 13 else { return }
        guard machine.apply(.codeSeen(code)) else { return }

        // The tick belongs to the barcode, not to the network: the user gets it as the row
        // rises, not a round-trip later.
        Haptics.Impact.soft.play()

        lookupTask?.cancel()
        lookupTask = Task { [weak self] in
            await self?.lookUp(code: code, entityModel: entityModel, modelContext: modelContext)
        }
    }

    private func lookUp(
        code: String,
        entityModel: EntityModel,
        modelContext: ModelContext
    ) async {
        do {
            // `isbn:` is the uri we can *ask* with; what comes back is keyed by inventaire's
            // own canonical id, and that is what the item has to be created from.
            guard let edition = try await entityModel.refreshEdition(
                modelContext: modelContext,
                uri: "isbn:\(code)"
            ) else {
                machine.apply(.lookupFailed(code: code))
                return
            }

            machine.apply(.lookupResolved(scannedBook(from: edition, code: code)))
        } catch {
            // Telling the user *why* — unknown edition, timeout — is issue 0019. Here the row
            // simply steps aside, with the code left gated so it is not re-offered on sight.
            machine.apply(.lookupFailed(code: code))
        }
    }

    // MARK: - Adding

    /// Files the pending book, then confirms and clears itself.
    func addPendingBook(
        inventoryModel: InventoryModel,
        userModel: UserModel,
        modelContext: ModelContext
    ) {
        guard case .resolved(let book) = state, let user = userModel.myUser else { return }
        guard machine.apply(.addStarted) else { return }

        addTask?.cancel()
        addTask = Task { [weak self] in
            guard let self else { return }
            do {
                // Same defaults as the book screen's add, and on no étagère, so a book filed
                // here is indistinguishable from one filed there.
                _ = try await inventoryModel.postNewItem(
                    modelContext: modelContext,
                    entityUri: book.uri,
                    transaction: .inventorying,
                    visibility: [.friends],
                    forUser: user
                )
                machine.apply(.addFinished)

                try? await Task.sleep(for: BatchScanViewModel.confirmationDuration)
                guard !Task.isCancelled else { return }
                machine.apply(.cleared)
            } catch {
                // Back to the offer: the book stays on screen and the action is tappable
                // again. Surfacing the error to the user is issue 0019.
                machine.apply(.addFailed)
            }
        }
    }

    // MARK: - Lifecycle

    /// Drops the pending row and the work behind it — on leaving the flow, or when the user
    /// walks away into the book screen.
    func cancelPending() {
        lookupTask?.cancel()
        addTask?.cancel()
        machine.apply(.cleared)
    }

    // MARK: - Private helpers

    /// Flattens the SwiftData edition into the value the row and the machine speak in.
    private func scannedBook(from edition: Edition, code: String) -> ScannedBook {
        let names: [String] = edition.authors.isEmpty
            ? edition.authorNames
            : edition.authors.map(\.name)

        return .init(
            uri: edition.uri,
            title: edition.title,
            authors: names,
            coverImageUrl: edition.image,
            code: code
        )
    }
}
