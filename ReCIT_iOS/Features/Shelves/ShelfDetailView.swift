//
//  ShelfDetailView.swift
//  ReCIT_iOS
//
//  A single étagère opened as a standard list of its books (same cell as the rest of
//  the inventory). Reached by tapping a shelf. See ADR 0003.
//
//  This is also where the étagère is edited: the shelf is a property of the screen that
//  shows it, so its form belongs to this screen's navigation bar rather than to the card
//  that led here. See PRD 0003.
//
//  Tidying is a gesture here rather than a trip through the book screen's menu: swiping a
//  row takes the book off *this* étagère, through the same optimistic write the menu calls.
//  See PRD 0004.
//
//  The form can also delete the étagère, which is a screen deleting its own subject: the
//  shelf is looked up by id, so afterwards it resolves to nothing and this screen has
//  nothing left to show. It leaves with the sheet. See issue 0021.
//
//  The same screen opens a friend's étagère, reached from the carousel on their profile, and
//  there it is read-only: neither of the two writing gestures above makes sense on someone
//  else's shelf, and the server would refuse them anyway. They are *absent* rather than
//  greyed out — a disabled button asks « pourquoi ? » and this screen has no answer to give
//  that the title and the route here have not already given. See issue 0093.
//

import SwiftUI
import SwiftData

struct ShelfDetailView: View {
    @Environment(ShelfModel.self) private var shelfModel
    @Environment(UserModel.self) private var userModel
    @Environment(\.modelContext) private var modelContext

    let shelfId: String
    @Binding var path: NavigationPath

    @Query private var shelves: [Shelf]

    @State private var editing: Bool = false

    /// Raised by the form when it deletes this screen's étagère, so the pop happens once
    /// the sheet has gone rather than out from under it.
    @State private var shelfWasDeleted: Bool = false

    init(shelfId: String, path: Binding<NavigationPath>) {
        self.shelfId = shelfId
        self._path = path
        _shelves = Query(filter: #Predicate { $0._id == shelfId })
    }

    private var shelf: Shelf? { shelves.first }

    /// Whether this screen may write to the étagère it shows.
    ///
    /// Derived from the shelf's owner rather than passed in as a flag: a third caller added
    /// later can pass a flag wrongly, and a shelf cannot lie about whose it is. An étagère
    /// that has not resolved — deleted, or not synced yet — is not mine either, which keeps
    /// the gate closed on a screen that has nothing to act on.
    private var isMine: Bool {
        guard let shelf else { return false }
        return shelf.ownerId == userModel.myUser?._id
    }

    /// This étagère's books, newest first.
    ///
    /// Deleted copies are dropped before `created` is read. Unlike an inventory list, these come
    /// from a relationship rather than a `@Query`, so a book deleted from its own screen — pushed
    /// from this very list — can still be in the array when this screen redraws behind it. See
    /// `PersistentModel+StillInTheStore` and issue 0065.
    private var books: [InventoryItem] {
        (shelf?.items ?? [])
            .filter(\.isStillInTheStore)
            .sorted { $0.created > $1.created }
    }

    var body: some View {
        List {
            if books.isEmpty {
                Text("Cette étagère est vide")
                    .textStyle(.action200)
                    .foregroundStyle(.foregroundSecondary)
            } else if let shelf {
                ForEach(books) { item in
                    NavigationLink(value: NavigationDestination.book(anchor: .item(item))) {
                        InventoryCell(item: item, filterParameter: .userInventory)
                    }
                    // Neither destructive nor red: nothing is deleted here — the copy stays
                    // in the inventory and on every other étagère — and red would teach the
                    // user to fear an action that costs one tap to undo. That means giving
                    // up the trailing-swipe red iOS uses for removal, deliberately. The icon
                    // lifts the book off the stack rather than binning it, and matches the
                    // book menu's own remove entry.
                    //
                    // Full swipe left on: the write is cheap and reversible, and clearing
                    // several books off a shelf shouldn't cost a tap each.
                    //
                    // The label names the étagère instead of saying "a shelf" — the screen
                    // already stands for one, and a long name simply truncates.
                    //
                    // Offered only on my own étagère: taking a book off someone else's
                    // shelf is not a gesture that exists, and a swipe that reveals an
                    // action only to refuse it is worse than no swipe at all.
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        if isMine {
                            Button("action.remove_from_shelf_named \(shelf.name)", systemImage: "tray.and.arrow.up") {
                                shelfModel.removeItem(item, from: shelf, modelContext: modelContext)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(shelf?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Gated on the lookup: the shelf comes back optional, and an ungated button would
            // open a form with no shelf to edit — which silently behaves as a *create* for an
            // étagère that was deleted or hasn't synced yet.
            //
            // Primary action rather than confirmation action: the confirmation slot means
            // "Done/Save" for a modal and renders prominent, which is the wrong weight for a
            // secondary action on a pushed screen. Title alongside the icon so a pencil on a
            // shelf of books isn't mistaken for annotating a book.
            //
            // And gated on ownership: `isMine` is false for an étagère that did not
            // resolve, so the same test covers both — a shelf that is not mine, and a
            // shelf that is not there.
            if isMine {
                ToolbarItem(placement: .primaryAction) {
                    Button("Modifier", systemImage: "pencil") { editing = true }
                        .labelStyle(.titleAndIcon)
                }
            }
        }
        .sheet(isPresented: $editing, onDismiss: leaveIfShelfWasDeleted) {
            if let shelf {
                ShelfFormView(shelf: shelf) { shelfWasDeleted = true }
            }
        }
    }

    /// Pops this screen once the form that deleted its étagère has closed. Without it the
    /// screen sits on an id that no longer resolves: an empty title over an empty list,
    /// with a "Modifier" action that has gone too.
    ///
    /// Driven by the form's own signal rather than reactively by the lookup turning nil,
    /// because popping is only correct while this screen is the top of the stack — which
    /// the sheet it presented guarantees, and a background sync dropping the shelf while
    /// the user is deeper in the stack would not.
    private func leaveIfShelfWasDeleted() {
        guard shelfWasDeleted, path.isEmpty == false else { return }
        path.removeLast()
    }
}
