//
//  BookMyCopyPage.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 22/11/2026.
//

import SwiftUI

/// The Fiche livre's Mon exemplaire: my copy — its two notes, its status, the day I added it — or,
/// when I own none, the pill that adds it; then « Dans mes listes », closed by « Ajouter à une
/// liste ».
///
/// It owns the notes' focus and the keyboard's « OK »: the page lives in a hosting controller of
/// its own, which a `@FocusState` held by the screen does not reach.
struct BookMyCopyPage: View {
    private let layout: FoldingHeaderPageLayout<BookTab>
    private let edition: Edition

    @FocusState private var focusedText: InventoryItemTextAttribute?

    @Binding private var creationRequest: ContainerCreationRequest?

    @Environment(UserModel.self) private var userModel: UserModel

    init(
        _ layout: FoldingHeaderPageLayout<BookTab>,
        edition: Edition,
        creationRequest: Binding<ContainerCreationRequest?>
    ) {
        self.layout = layout
        self.edition = edition
        _creationRequest = creationRequest
    }

    /// My copy of this edition, if I have one.
    ///
    /// The `isStillInTheStore` test comes first because this runs on the screen that does the
    /// deleting: `edition.items` can still hold the copy that was just removed, and `ownerId` is
    /// a persisted read that traps on it. See `PersistentModel+StillInTheStore` and issue 0065.
    private var myCopy: InventoryItem? {
        edition.items.first { $0.isStillInTheStore && $0.ownerId == userModel.myUser?._id }
    }

    /// Listes hold works, not editions: an edition standing behind several works offers no way to
    /// add it to one, as in the « … » menu.
    private var listedWorkUri: String? {
        edition.workUris.count == 1 ? edition.workUris.first : nil
    }

    var body: some View {
        FoldingHeaderPage(layout) {
            Group {
                if let myCopy {
                    BookMyCopySection(item: myCopy, focus: $focusedText)
                } else {
                    BookAbsentCopySection(edition)
                }

                BookListEntriesReader(workUris: edition.workUris, myUserId: userModel.myUser?._id) { entries in
                    let mine: [BookListEntry] = entries.filter(\.isMine)
                    if mine.isEmpty == false || listedWorkUri != nil {
                        BookListsSection("book.my_lists", entries: mine) {
                            if let listedWorkUri {
                                addToListRow(workUri: listedWorkUri)
                            }
                        }
                    }
                }
            }
            .listRowBackground(DesignSystem.Color.backgroundFormCell.color)
        }
        .toolbar {
            KeyboardOKButton {
                focusedText = nil
            }
        }
    }

    /// The « … » menu's list menu, standing alone: the lists to add the work to or take it out of,
    /// and a new one.
    private func addToListRow(workUri: String) -> some View {
        EntityListMenu(
            entityUri: workUri,
            identifier: AccessibilityID.addToList,
            creationRequest: $creationRequest
        )
        .title("book.my_lists.add")
        .labelStyle(.titleOnly)
        .textStyle(.action300)
        .foregroundStyle(.foregroundTinted)
    }
}

private extension BookMyCopyPage {
    enum AccessibilityID {
        static let addToList: String = "e2e.book.myLists.addToList"
    }
}

#Preview {
    @Previewable @State var creationRequest: ContainerCreationRequest?

    BookMyCopyPage(
        .init(
            page: .myCopy,
            expandedHeaderHeight: 0,
            headerTop: nil,
            collapse: .init(distance: 0),
            scrollOffset: .init(),
            isFrozen: false
        ),
        edition: .init(uri: "isbn:9782070360024", title: "L'Étranger", lang: "fr", authorNames: []),
        creationRequest: $creationRequest
    )
}
