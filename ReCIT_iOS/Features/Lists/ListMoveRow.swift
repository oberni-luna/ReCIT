//
//  ListMoveRow.swift
//  ReCIT_iOS
//
//  « Déplacer dans une autre liste » on the selected element: a menu of the user's other lists
//  of the same type, the selected element moved into the one picked, with its comment.
//
//  The move is server-first (`ListModel.moveElement`): the row spins while it runs, the element
//  leaves the cover flow once the server has answered, and a SnackBar says where it went — or
//  the shared reporter says what failed. The row says nothing while the comment is being written,
//  since the draft is only saved once the field is left, nor for an element the server has not
//  created yet. With no other list of the type, there is no row at all.
//

import LBSnackBar
import SwiftData
import SwiftUI

struct ListMoveRow: View {
    let item: EntityListItem
    let list: EntityList
    let isCommentFocused: Bool

    @Environment(ListModel.self) private var listModel
    @Environment(AppErrorReporter.self) private var errorReporter
    @Environment(\.modelContext) private var modelContext
    @Environment(\.snackBar) private var snackBar
    @Environment(UserModel.self) private var userModel

    @Query(sort: \EntityList.name) private var storedLists: [EntityList]

    /// Mine only: a friend's lists, stored for their profile, are not mine to file into.
    private var lists: [EntityList] {
        storedLists.filter { $0.isCreated(byMe: userModel.myUser?._id) }
    }

    @State private var isMoving: Bool = false

    private var destinations: [ListMoveDestination] {
        ListMoveDestination.destinations(
            for: item.uri,
            from: list._id,
            type: list.type,
            among: lists.map { candidate in
                .init(
                    id: candidate._id,
                    name: candidate.name,
                    type: candidate.type,
                    uris: .init(candidate.elements.filter(\.isStillInTheStore).map(\.uri))
                )
            }
        )
    }

    var body: some View {
        if destinations.isEmpty == false {
            Menu {
                ForEach(destinations) { destination in
                    Button {
                        move(to: destination)
                    } label: {
                        Text(destination.name)
                        if destination.alreadyHolds {
                            Text("list.detail.move.already")
                        }
                    }
                    .disabled(destination.alreadyHolds)
                }
            } label: {
                HStack(spacing: .small) {
                    Text("list.detail.move")
                        .textStyle(.action300)
                        .foregroundStyle(.foregroundTinted)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if isMoving {
                        ProgressView()
                    }
                }
            }
            .disabled(isMoving || isCommentFocused || OptimisticID.isOptimistic(item._id))
            .accessibilityIdentifier("e2e.listMove")
        }
    }

    private func move(to destination: ListMoveDestination) {
        guard let target = lists.first(where: { $0._id == destination.id }) else { return }

        let name: String = destination.name
        isMoving = true
        Task {
            defer { isMoving = false }
            do {
                try await listModel.moveElement(
                    modelContext: modelContext,
                    item: item,
                    from: list,
                    to: target
                )
                snackBar.show {
                    SnackBarView(title: String(localized: "list.detail.moved_to_named \(name)"), onDismiss: nil)
                }
            } catch {
                errorReporter.report(error)
            }
        }
    }
}
