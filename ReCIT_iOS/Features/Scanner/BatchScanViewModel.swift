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
//  confirm and clear. That is also what makes the session's tally trustworthy: the machine only
//  ever counts a book the server has acknowledged.
//
//  See PRD 0005 and PRD 0007.
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

    /// How long a notice the user cannot act on — an unknown edition, a book already filed —
    /// stays up. Longer than the confirmation because there is a sentence to read, but
    /// bounded all the same: the row is what stops the next scan, so a notice that never
    /// cleared would strand the flow on a book nothing can be done about.
    private static let noticeDuration: Duration = .seconds(3)

    /// How long a lookup may run before the row gives up on it. The redacted row pulses
    /// meanwhile, and on a bad connection a round-trip is unbounded; ten seconds is past any
    /// answer worth waiting for and short enough that the shelf keeps moving.
    private static let lookupTimeout: Duration = .seconds(10)

    private var machine: BatchScanStateMachine = .init()

    @ObservationIgnored private var lookupTask: Task<Void, Never>?
    @ObservationIgnored private var addTask: Task<Void, Never>?
    /// Owns the clearing of a notice row, and nothing else. Kept apart from `lookupTask`
    /// because a timed-out lookup outlives the lookup that produced it: the network call is
    /// abandoned, but the row it left behind still has to be taken down.
    @ObservationIgnored private var noticeTask: Task<Void, Never>?

    var state: BatchScanState {
        machine.state
    }

    /// How many books this session has filed, straight from the machine. No counter of its own:
    /// the machine is the only type that knows which add events were real, and a second tally
    /// kept here would be free to disagree with it.
    var addedBookCount: Int {
        machine.addedBookCount
    }

    // MARK: - Camera

    /// A barcode is in frame. Called for every frame the camera resolves one, so most calls
    /// are expected to be refused by the gate.
    func codeSeen(
        _ code: String,
        entityModel: EntityModel,
        userModel: UserModel,
        modelContext: ModelContext
    ) {
        guard code.count == 13 else { return }
        guard machine.apply(.codeSeen(code)) else { return }

        // The tick belongs to the barcode, not to the network: the user gets it as the row
        // rises, not a round-trip later.
        Haptics.Impact.soft.play()

        lookupTask?.cancel()
        lookupTask = Task { [weak self] in
            await self?.lookUp(
                code: code,
                entityModel: entityModel,
                userModel: userModel,
                modelContext: modelContext
            )
        }
    }

    private func lookUp(
        code: String,
        entityModel: EntityModel,
        userModel: UserModel,
        modelContext: ModelContext
    ) async {
        // A watchdog rather than a race between two child tasks: the edition is a SwiftData
        // model and never leaves this actor. Firing it abandons the request — `showNotice`
        // cancels the lookup — and anything the network says afterwards is refused by the
        // machine, which is no longer waiting for this code.
        let deadline: Task<Void, Never> = Task { [weak self] in
            try? await Task.sleep(for: BatchScanViewModel.lookupTimeout)
            guard !Task.isCancelled else { return }
            self?.showNotice(.lookupTimedOut(code: code), haptic: .error)
        }
        defer { deadline.cancel() }

        do {
            // `isbn:` is the uri we can *ask* with; what comes back is keyed by inventaire's
            // own canonical id, and that is what the item has to be created from.
            //
            // **Asked with `autocreate`**, which is what the website's own scanner does: for an
            // ISBN its book-facts service knows, inventaire.io writes the edition itself —
            // title, date, publisher, language, work and cover — and hands it back as if it had
            // always been there. Most barcodes that used to land on « this edition does not
            // exist » now simply resolve. What is left over, the ISBNs nothing knows, is what
            // the creation form is for. See feature 0020.
            guard let edition = try await entityModel.refreshEdition(
                modelContext: modelContext,
                uri: "isbn:\(code)",
                autocreate: true
            ) else {
                showNotice(.lookupFailed(code: code), haptic: .error)
                return
            }

            let book: ScannedBook = scannedBook(from: edition, code: code)

            if isAlreadyOwned(book: book, userModel: userModel, modelContext: modelContext) {
                // Not an error — a book the user simply has — so it gets its own haptic
                // rather than the failure one.
                showNotice(.lookupResolvedAlreadyOwned(book), haptic: .warning)
                return
            }

            machine.apply(.lookupResolved(book))
        } catch {
            showNotice(.lookupFailed(code: code), haptic: .error)
        }
    }

    // MARK: - Adding

    /// Files the pending book, then confirms and clears itself. `onFailure` carries a failed
    /// add out to the view: the scanner is a full-screen modal over the tab bar, and a book
    /// the user believes was filed and was not is the one outcome this flow cannot afford.
    func addPendingBook(
        inventoryModel: InventoryModel,
        userModel: UserModel,
        modelContext: ModelContext,
        onFailure: @escaping @MainActor (Error) -> Void
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
                // again, with the failure said out loud so the user does not walk away
                // believing it landed.
                machine.apply(.addFailed)
                Haptics.Notification.error.play()
                onFailure(error)
            }
        }
    }

    // MARK: - Creating

    /// Drafts of books being created, by ISBN. The sheet is short-lived and the session is not:
    /// a publication that failed leaves what was typed here, so closing the form and coming
    /// back to the same barcode finds it again rather than asking for it twice (issue 0096).
    @ObservationIgnored private var drafts: [String: NewBookDraft] = [:]

    /// What the form opens on for this barcode: the draft left from a previous attempt, or a
    /// blank one.
    func draft(forISBN isbn: String) -> NewBookDraft {
        drafts[isbn] ?? .init(isbn: isbn)
    }

    /// Keeps what was typed. Called as the form goes, whatever took it away.
    func remember(_ draft: NewBookDraft) {
        drafts[draft.isbn] = draft
    }

    /// Forgets a draft that has become a book. Nothing else clears one: a session's worth of
    /// abandoned drafts is a few hundred bytes, and losing one is worse than keeping it.
    func forgetDraft(forISBN isbn: String) {
        drafts[isbn] = nil
    }

    /// Confirms the book the reader has just created on inventaire.io, which is already in
    /// their inventory: the form does both writes and hands the result back here.
    ///
    /// Same ending as an add — the green row, held as proof, then the screen given back to the
    /// camera — because from the reader's side the two are the same act. The tally moves in the
    /// machine, for the same reason it does there: it is the one type that knows the event was
    /// real. See PRD 0015.
    func bookCreated(_ book: ScannedBook) {
        forgetDraft(forISBN: book.code)

        guard machine.apply(.creationFinished(book)) else { return }

        Haptics.Notification.success.play()

        addTask?.cancel()
        addTask = Task { [weak self] in
            try? await Task.sleep(for: BatchScanViewModel.confirmationDuration)
            guard !Task.isCancelled else { return }
            self?.machine.apply(.cleared)
        }
    }

    // MARK: - Lifecycle

    /// Drops the pending row and the work behind it — on leaving the flow, or when the user
    /// walks away into the book screen.
    func cancelPending() {
        lookupTask?.cancel()
        addTask?.cancel()
        noticeTask?.cancel()
        machine.apply(.cleared)
    }

    // MARK: - Ending the session

    /// How many étagères the user owns — the other half of the bilan's condition, and the only
    /// thing about them this flow asks.
    ///
    /// Fetched rather than queried, unlike everywhere else. A `@Query` would hold every étagère
    /// in the store for as long as the camera is up, and re-render the feed whenever one changed,
    /// to answer a question asked exactly once: at the moment the session ends. Same shape as the
    /// already-owned check further down, and for the same reason.
    func ownedShelfCount(userModel: UserModel, modelContext: ModelContext) -> Int {
        guard let ownerId = userModel.myUser?._id else { return 0 }

        let descriptor: FetchDescriptor<Shelf> = .init(
            predicate: #Predicate { $0.ownerId == ownerId }
        )
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    // MARK: - Private helpers

    /// Puts up an outcome of a lookup, and takes it down again when there is nothing to be
    /// done about it.
    ///
    /// A book the inventory already holds ends by itself: the row is what stops the next
    /// barcode being accepted, and there is no action on it for the user to end it with. An
    /// **unknown edition does not** — since issue 0090 it carries the offer to create the book,
    /// and an offer that vanishes after three seconds is worse than no offer at all. What ends
    /// it instead is the next book: the state machine lets a *different* barcode take the row.
    private func showNotice(_ event: BatchScanEvent, haptic: Haptics.Notification) {
        guard machine.apply(event) else { return }

        // Distinct from the recognition tick, so a shelf can be worked through by feel: a
        // book that answered and a book that did not are told apart without looking up.
        haptic.play()

        lookupTask?.cancel()
        noticeTask?.cancel()

        guard machine.state.holdsUntilActedOn == false else { return }

        noticeTask = Task { [weak self] in
            try? await Task.sleep(for: BatchScanViewModel.noticeDuration)
            guard !Task.isCancelled else { return }
            self?.machine.apply(.cleared)
        }
    }

    /// Whether the user already has a copy of the resolved edition.
    ///
    /// **Matched on the canonical uri the server answered with, never on the `isbn:` uri the
    /// lookup asked with.** inventaire keys an edition by its own `inv:` id — the same fact
    /// `EditionPagesLoader` documents — and an inventory item is created from, and stores,
    /// that canonical uri. Matching on the requested uri would compare `isbn:…` against
    /// `inv:…`, never fire, and quietly duplicate every book on a second pass over a shelf,
    /// with nothing on screen to say so. `ScannedBook.uri` is that canonical uri by
    /// construction. See PRD 0005.
    private func isAlreadyOwned(
        book: ScannedBook,
        userModel: UserModel,
        modelContext: ModelContext
    ) -> Bool {
        guard let ownerId = userModel.myUser?._id, book.uri.isEmpty == false else { return false }

        let descriptor: FetchDescriptor<InventoryItem> = .init(
            predicate: BookViewModel.ownedItemsPredicate(
                editionUri: book.uri,
                ownerId: ownerId
            )
        )
        return ((try? modelContext.fetchCount(descriptor)) ?? 0) > 0
    }

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
