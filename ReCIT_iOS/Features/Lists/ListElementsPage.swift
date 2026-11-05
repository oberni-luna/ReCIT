//
//  ListElementsPage.swift
//  ReCIT_iOS
//
//  A list's « Livres » page: the cover flow, the element facing the reader below it, and — in
//  place of the tab bar — the bar to add one more. One page of `ListCoverFlowScreen`'s pager, an
//  inset grouped list of its own (`DesignSystem.FormList`).
//
//  **It owns the comment's focus and the keyboard.** The page lives in a hosting controller of
//  its own, which a `@FocusState` held by the screen does not reach; so the focus, the keyboard's
//  frame, the keyboard's « OK » and the room left under the list while the comment is written are
//  here, and the screen is only told whether a comment is being written — to hold the pager still.
//  The add bar is here too, so it slides away with the page.
//
//  **The swap between two books is a cross-fade.** Every row that speaks of the selected book is
//  keyed on its uri (`ListCrossFade`) and replaced as a whole, under one short ease, while the
//  covers above follow the finger at every frame.
//
//  **A friend's list is read, not written**: no add bar, no « Mon commentaire », « Déplacer » or
//  « Retirer de la liste » — their comment and the day the element was added.
//

import SwiftUI
// The keyboard's frame, which the list keeps to itself.
import UIKit

struct ListElementsPage: View {
    /// The room left under the list while the comment is written, when the keyboard's own height
    /// is not known yet.
    private static let minimumKeyboardRoom: CGFloat = 320

    let list: EntityList
    let items: [EntityListItem]
    let isMine: Bool
    @Binding var selectedURI: String?
    /// The cover ringed on arriving from a book screen, whose title VoiceOver moves to.
    let highlightedURI: String?
    /// Told whether the comment is being written, for the screen to hold its pager still.
    @Binding var isWritingComment: Bool
    /// The height of the tabs laid over the page, which it leaves room for.
    let tabsHeight: CGFloat
    let onScan: () -> Void
    let onSearch: () -> Void
    let onOpen: (String) -> Void
    let onRemove: (EntityListItem) -> Void

    @FocusState private var isCommentFocused: Bool
    @AccessibilityFocusState private var isTitleFocused: Bool
    /// Bumped by every edit of the comment and by its focus: what makes the list follow the field
    /// as it grows (`ListKeyboardReveal`).
    @State private var commentEdits: Int = 0
    /// The top of the keyboard on screen, `.infinity` when it is down. Read from UIKit: the list
    /// keeps the keyboard to itself.
    @State private var keyboardTop: CGFloat = .infinity
    /// The keyboard's height, for the room left under the list while the comment is written.
    @State private var keyboardHeight: CGFloat = 0

    private var uris: [String] {
        items.map(\.uri)
    }

    private var selectedItem: EntityListItem? {
        items.first { $0.uri == selectedURI }
    }

    var body: some View {
        if list.isStillInTheStore {
            DesignSystem.FormList {
                elementSections

                // Room for the comment to rise into. Below the comment the list holds only « Retirer de
                // la liste » and its footer: it was already scrolled as far as it goes, so neither the
                // caret nor `ListKeyboardReveal` could take the growing field any higher, and each new line
                // went under the keyboard. A transparent row as tall as the keyboard, while the
                // comment is being written.
                if isCommentFocused {
                    Section {
                        Color.clear
                            // At least a keyboard's worth even before its frame is known: a hardware
                            // keyboard first reports a sliver, and the room has to be there already.
                            .frame(height: max(keyboardHeight, Self.minimumKeyboardRoom))
                            .listRowBackground(Color.clear)
                            .listRowInsets(.init())
                    }
                }
            }
            .listDetailTabsRoom(height: tabsHeight)
            .scrollDismissesKeyboard(.interactively)
            .formActionBar(isPresented: isMine && isCommentFocused == false) {
                ListAddBar(
                    listType: list.type,
                    onScan: onScan,
                    onSearch: onSearch
                )
            }
            .toolbar {
                // The comment spans lines, so the return key starts a new one: this is the way to
                // say the comment is done, and leaving the field is what writes it.
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()

                    Button("action.ok") {
                        isCommentFocused = false
                    }
                }
            }
            .task {
                for await notification in NotificationCenter.default.notifications(
                    named: UIResponder.keyboardWillShowNotification
                ) {
                    let frame: CGRect? = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
                    keyboardTop = frame?.minY ?? .infinity
                    keyboardHeight = frame?.height ?? 0
                }
            }
            .task {
                for await _ in NotificationCenter.default.notifications(
                    named: UIResponder.keyboardWillHideNotification
                ) {
                    keyboardTop = .infinity
                }
            }
            .onChange(of: highlightedURI) { _, uri in
                if uri != nil {
                    isTitleFocused = true
                }
            }
            .onChange(of: isCommentFocused) { _, focused in
                if focused {
                    commentEdits += 1
                }
                isWritingComment = focused
            }
        }
    }

    /// The cover flow, the selected element and what may be done with it.
    @ViewBuilder
    private var elementSections: some View {
        if items.isEmpty {
            Section {
                Text("list.empty")
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundSecondary)
            }
        } else {
            // The cover flow and the title, edge to edge on the screen's own ground: a row
            // dressed as a header. A real section header lays its horizontal scroll view out
            // before it has a width, and the strip came up empty.
            Section {
                VStack(spacing: .zero) {
                    ListCoverFlowView(
                        uris: uris,
                        listType: list.type,
                        selectedURI: $selectedURI,
                        highlightedURI: highlightedURI,
                        onOpen: onOpen
                    )

                    if let selectedURI {
                        ListCrossFade(id: selectedURI) {
                            ListSelectedTitle(uri: selectedURI, listType: list.type)
                                .accessibilityElement(children: .combine)
                                .accessibilityFocused($isTitleFocused)
                        }
                        .padding(.horizontal, .medium)
                    }
                }
                .listRowInsets(.init())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            // Edge to edge from iOS 26, so the turned covers are not cut at the section's
            // margin; before it the section keeps the list's margins.
            .listSectionHorizontalMargins(0)

            if isMine {
                Section {
                    if let selectedItem {
                        ListCrossFade(id: selectedItem.uri) {
                            ListCommentRow(
                                item: selectedItem,
                                listType: list.type,
                                isFocused: $isCommentFocused,
                                onEdit: { commentEdits += 1 }
                            )
                        }
                        .background {
                            ListKeyboardReveal(trigger: commentEdits, keyboardTop: keyboardTop)
                        }

                        // No way to the element's page here: the cover in front opens it.
                        ListMoveRow(
                            item: selectedItem,
                            list: list,
                            isCommentFocused: isCommentFocused
                        )
                    }
                }

                if let selectedItem {
                    Section {
                        Button("list.detail.remove", role: .destructive) {
                            onRemove(selectedItem)
                        }
                        .textStyle(.action300)
                        .foregroundStyle(.foregroundError)
                    } footer: {
                        addedFooter(selectedItem)
                    }
                }
            } else if let selectedItem {
                // Their comment when they wrote one, and the day the element was added.
                Section {
                    if selectedItem.comment.isEmpty == false {
                        ListCrossFade(id: selectedItem.uri) {
                            ListReadOnlyCommentRow(comment: selectedItem.comment)
                        }
                    }
                } footer: {
                    addedFooter(selectedItem)
                }
            }
        }
    }

    private func addedFooter(_ item: EntityListItem) -> some View {
        ListCrossFade(id: item.uri) {
            Text("list.detail.added \(item.created.formatted(.dateTime.day().month(.wide).year()))")
                .textStyle(.footnote200)
                .foregroundStyle(.foregroundSecondary)
                .frame(maxWidth: .infinity)
        }
    }
}
