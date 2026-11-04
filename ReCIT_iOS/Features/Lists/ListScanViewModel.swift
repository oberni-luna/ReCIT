//
//  ListScanViewModel.swift
//  ReCIT_iOS
//
//  Turns the barcodes the list's scanner sees into the one book it offers to add, and that book
//  into the works a list can hold.
//
//  The gate is the batch scanner's own `BatchScanStateMachine`: a barcode held in frame is read
//  several times a second, and the machine is what decides which of those sightings count, which
//  row a different barcode may replace, and which lookup answer is still awaited. Only its lookup
//  half is used here — the list's « + » does not file anything into the inventory, it hands the
//  works to the list and the scanner closes.
//
//  An edition with no work behind it cannot go in a list, so it is told like an edition
//  inventaire.io does not have: the row says so, and the next barcode takes its place.
//
//  See PRD 0029.
//

import Foundation
import SwiftData

@MainActor
@Observable
final class ListScanViewModel {
    /// How long a lookup may run before the row gives up on it, as in the batch scanner.
    private static let lookupTimeout: Duration = .seconds(10)

    private var machine: BatchScanStateMachine = .init()

    /// The works of the book the row is offering, in the edition's order.
    private(set) var works: [ListWorkOption] = []

    @ObservationIgnored private var lookupTask: Task<Void, Never>?

    var state: BatchScanState {
        machine.state
    }

    /// A barcode is in frame. Most calls are refused by the gate.
    func codeSeen(_ code: String, entityModel: EntityModel, modelContext: ModelContext) {
        guard code.count == 13 else { return }
        guard machine.apply(.codeSeen(code)) else { return }

        Haptics.Impact.soft.play()
        works = []

        lookupTask?.cancel()
        lookupTask = Task { [weak self] in
            await self?.lookUp(code: code, entityModel: entityModel, modelContext: modelContext)
        }
    }

    /// Gives the screen back to the camera — after « Continuer », when the book was already there.
    func clear() {
        lookupTask?.cancel()
        works = []
        machine.apply(.cleared)
    }

    private func lookUp(code: String, entityModel: EntityModel, modelContext: ModelContext) async {
        let deadline: Task<Void, Never> = Task { [weak self] in
            try? await Task.sleep(for: ListScanViewModel.lookupTimeout)
            guard !Task.isCancelled else { return }
            self?.fail(.lookupTimedOut(code: code))
        }
        defer { deadline.cancel() }

        do {
            // Asked with `autocreate`, as the batch scanner does: inventaire.io writes the
            // editions its book-facts service knows, works included.
            guard let edition = try await entityModel.refreshEdition(
                modelContext: modelContext,
                uri: "isbn:\(code)",
                autocreate: true
            ), edition.works.isEmpty == false else {
                fail(.lookupFailed(code: code))
                return
            }

            let names: [String] = edition.authors.isEmpty ? edition.authorNames : edition.authors.map(\.name)
            let book: ScannedBook = .init(
                uri: edition.uri,
                title: edition.title,
                authors: names,
                coverImageUrl: edition.image,
                code: code
            )
            let options: [ListWorkOption] = edition.works.map { .init(uri: $0.uri, title: $0.title) }

            guard machine.apply(.lookupResolved(book)) else { return }
            works = options
        } catch {
            fail(.lookupFailed(code: code))
        }
    }

    private func fail(_ event: BatchScanEvent) {
        guard machine.apply(event) else { return }

        Haptics.Notification.error.play()
        lookupTask?.cancel()
    }
}
