//
//  ListCommentRow.swift
//  ReCIT_iOS
//
//  « Mon commentaire » on the selected element: the reader's own words on why it is in the list.
//
//  **The comment is written when it is left** — the field losing focus, or the book being swiped
//  away while it had it, which takes this row off screen. `ListModel.updateComment` is optimistic
//  and sends nothing for an unchanged text, so the two can both fire without a second request.
//  The field is disabled while the element still has its optimistic id: the server cannot be told
//  about an element it has not created yet.
//
//  The screen keys this row on the selected uri, so every book has its own draft.
//
//  See PRD 0029.
//

import SwiftData
import SwiftUI

struct ListCommentRow: View {
    let item: EntityListItem
    let listType: EntityListType
    var isFocused: FocusState<Bool>.Binding
    /// Told of every edit, so the screen can keep the growing field above the keyboard.
    let onEdit: () -> Void

    @Environment(ListModel.self) private var listModel
    @Environment(\.modelContext) private var modelContext

    @State private var draft: String

    init(
        item: EntityListItem,
        listType: EntityListType,
        isFocused: FocusState<Bool>.Binding,
        onEdit: @escaping () -> Void
    ) {
        self.item = item
        self.listType = listType
        self.isFocused = isFocused
        self.onEdit = onEdit
        _draft = State(initialValue: item.comment)
    }

    private var prompt: LocalizedStringKey {
        listType == .author ? "list.detail.comment.placeholder.author" : "list.detail.comment.placeholder.work"
    }

    var body: some View {
        if item.isStillInTheStore {
            VStack(alignment: .leading, spacing: .xSmall) {
                Text("list.detail.comment.label")
                    .textStyle(.footnote200)
                    .foregroundStyle(.foregroundSecondary)

                TextField(
                    "list.detail.comment.label",
                    text: $draft,
                    prompt: Text(prompt),
                    axis: .vertical
                )
                // Four lines held even when empty, so going from one book to the next does not move
                // what is below; past four, the field grows.
                .lineLimit(4...)
                .textStyle(.content300)
                .foregroundStyle(.foregroundDefault)
                .focused(isFocused)
                .disabled(OptimisticID.isOptimistic(item._id))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .onChange(of: isFocused.wrappedValue) { _, focused in
                guard focused == false else { return }

                save()
            }
            .onChange(of: draft) {
                guard isFocused.wrappedValue else { return }

                onEdit()
            }
            .onChange(of: item.comment) { _, comment in
                // A sync or a reverted write moves the stored text; a draft being typed keeps its own.
                guard isFocused.wrappedValue == false else { return }

                draft = comment
            }
            .onDisappear(perform: save)
        }
    }

    private func save() {
        // The element may have just been removed from the list, which is also what takes this
        // row away: a property read on a deleted model is a trap, not a nil.
        guard item.isStillInTheStore else { return }

        listModel.updateComment(
            modelContext: modelContext,
            item: item,
            comment: draft.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
}
