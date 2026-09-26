//
//  WorkActions.swift
//  ReCIT_iOS
//
//  A work's actions — today, filing it in a list — written once and carried two ways: as
//  the "…" menu of the editions picker, and as the long-press menu of a work's row in a
//  list. Same shape as `BookActions`, for the same reason: the creation sheet has to live
//  outside the `Menu`, which a context menu is too.
//

import SwiftUI

extension View {
    func workActions(
        workUri: String,
        placement: ActionsPlacement
    ) -> some View {
        modifier(
            WorkActionsModifier(
                workUri: workUri,
                placement: placement
            )
        )
    }
}

struct WorkActionsModifier: ViewModifier {
    let workUri: String
    let placement: ActionsPlacement

    /// What the menu asks to create. Held here rather than by the menu: a `.sheet` placed
    /// inside a `Menu`'s content does not present reliably.
    @State private var creationRequest: ContainerCreationRequest?

    func body(content: Content) -> some View {
        placed(content)
            .containerCreationSheet($creationRequest)
    }

    @ViewBuilder
    private func placed(_ content: Content) -> some View {
        switch placement {
        case .toolbar:
            content.toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Menu {
                        // Glyphs in the label colour rather than the app's green — see BookActions.
                        menuContent
                            .tint(.foregroundDefault)
                    } label: {
                        Label("action.more", systemImage: "ellipsis")
                    }
                    .accessibilityIdentifier("e2e.work.menu")
                }
            }
        case .contextMenu:
            content.contextMenu {
                menuContent
                    .tint(.foregroundDefault)
            }
        }
    }

    private var menuContent: some View {
        EntityListMenu(
            entityUri: workUri,
            identifier: "e2e.work.addToList",
            creationRequest: $creationRequest
        )
    }
}
