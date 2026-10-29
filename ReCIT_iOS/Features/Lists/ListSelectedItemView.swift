//
//  ListSelectedItemView.swift
//  ReCIT_iOS
//
//  The bottom half of a list's screen: the element facing the reader in the cover flow — its
//  title, its author or description, the reader's comment on it, the way to its page, the way out
//  of the list, and the day it was added.
//
//  The screen keys this view on the selected uri, so moving to another book replaces it with a
//  fresh one rather than updating it in place: that is what lets the swap be a cross-fade, and
//  what gives every book its own draft of the comment.
//
//  **The comment is written when it is left** — the field losing focus, or the book being
//  swiped away while it had it, which takes this view off screen. `ListModel.updateComment` is
//  optimistic and sends nothing for an unchanged text, so the two can both fire without a second
//  request. The field is disabled while the element still has its optimistic id: the server
//  cannot be told about an element it has not created yet.
//
//  See PRD 0029.
//

import SwiftData
import SwiftUI

struct ListSelectedItemView: View {
    let item: EntityListItem
    let listType: EntityListType
    var isCommentFocused: FocusState<Bool>.Binding
    let onOpen: () -> Void
    let onRemove: () -> Void

    @Environment(ListModel.self) private var listModel
    @Environment(\.modelContext) private var modelContext

    @Query private var works: [Work]
    @Query private var authors: [Author]

    @State private var draft: String

    init(
        item: EntityListItem,
        listType: EntityListType,
        isCommentFocused: FocusState<Bool>.Binding,
        onOpen: @escaping () -> Void,
        onRemove: @escaping () -> Void
    ) {
        self.item = item
        self.listType = listType
        self.isCommentFocused = isCommentFocused
        self.onOpen = onOpen
        self.onRemove = onRemove
        let uri: String = item.uri
        _works = Query(filter: #Predicate<Work> { $0.uri == uri })
        _authors = Query(filter: #Predicate<Author> { $0.uri == uri })
        _draft = State(initialValue: item.comment)
    }

    private var title: String {
        switch listType {
        case .author:
            authors.first?.name ?? ""
        case .work, .publisher:
            works.first?.title ?? ""
        }
    }

    /// Under a work, its authors; under an author, what inventaire.io says they are.
    private var byline: String? {
        guard listType != .author else { return authors.first?.subtitle }
        guard let work = works.first else { return nil }

        let names: [String] = work.authors.map(\.name).filter { $0.isEmpty == false }
        return names.isEmpty ? work.subtitle : names.joined(separator: ", ")
    }

    private var commentPrompt: LocalizedStringKey {
        listType == .author ? "list.detail.comment.placeholder.author" : "list.detail.comment.placeholder.work"
    }

    private var openLabel: LocalizedStringKey {
        listType == .author ? "list.detail.open.author" : "list.detail.open.work"
    }

    var body: some View {
        VStack(spacing: .medium) {
            VStack(spacing: .xxSmall) {
                Text(title)
                    .textStyle(.content400Bold)
                    .foregroundStyle(.foregroundDefault)

                if let byline, byline.isEmpty == false {
                    Text(byline)
                        .textStyle(.content300)
                        .foregroundStyle(.foregroundSecondary)
                }
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)

            VStack(spacing: .zero) {
                VStack(alignment: .leading, spacing: .xSmall) {
                    Text("list.detail.comment.label")
                        .textStyle(.footnote200)
                        .foregroundStyle(.foregroundSecondary)

                    TextField(
                        "list.detail.comment.label",
                        text: $draft,
                        prompt: Text(commentPrompt),
                        axis: .vertical
                    )
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundDefault)
                    .focused(isCommentFocused)
                    .disabled(OptimisticID.isOptimistic(item._id))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, .medium)
                .padding(.vertical, .sMedium)

                Divider()
                    .padding(.leading, .medium)

                ListDetailRowButton(label: openLabel, color: .foregroundTinted, action: onOpen)
            }
            .background(.backgroundFormCell)
            .clipShape(.rect(cornerRadius: DesignSystem.CornerRadius.medium.rawValue))

            ListDetailRowButton(label: "list.detail.remove", color: .foregroundError, action: onRemove)
                .background(.backgroundFormCell)
                .clipShape(.rect(cornerRadius: DesignSystem.CornerRadius.medium.rawValue))

            Text("list.detail.added \(item.created.formatted(.dateTime.day().month(.wide).year()))")
                .textStyle(.footnote200)
                .foregroundStyle(.foregroundSecondary)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, .medium)
        .onChange(of: isCommentFocused.wrappedValue) { _, isFocused in
            guard isFocused == false else { return }

            saveComment()
        }
        .onChange(of: item.comment) { _, comment in
            // A sync or a reverted write moves the stored text; a draft being typed keeps its own.
            guard isCommentFocused.wrappedValue == false else { return }

            draft = comment
        }
        .onDisappear(perform: saveComment)
    }

    private func saveComment() {
        // The element may have just been removed from the list, which is also what takes this
        // view away: a property read on a deleted model is a trap, not a nil.
        guard item.isStillInTheStore else { return }

        listModel.updateComment(
            modelContext: modelContext,
            item: item,
            comment: draft.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
}
