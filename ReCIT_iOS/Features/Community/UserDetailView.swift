//
//  UserDetailView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 01/02/2026.
//

import SwiftUI

struct UserDetailView: View {
    @Environment(UserModel.self) private var userModel

    @State private var nextNavigationDestination: NavigationDestination?
    @State private var borrowFromItem: InventoryItem?

    let user: User
    @Binding var path: NavigationPath

    var body: some View {
        List {
            Section {
                UserHeaderView(user: user)
            }

            Section {
                if user.lastInventorySync == nil {
                    SyncingInlineRow()
                } else if user.items.isEmpty {
                    Text("inventory.empty")
                } else {
                    ForEach(user.items) { item in
                        Button {
                            path.append(NavigationDestination.book(anchor: .item(item)))
                        } label: {
                            InventoryCell(item: item, filterParameter: .userInventory)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            if item.ownerId != userModel.myUser?._id {
                                if item.transaction == .inventorying {
                                    Button("community.owner_not_lending \(user.username)", systemImage: "hand.raised.slash") { }
                                        .disabled(true)
                                } else {
                                    Button("action.borrow_from_user \(user.username)", systemImage: "hand.wave") {
                                        borrowFromItem = item
                                    }
                                }
                            }
                        }
                    }
                }
            } header: {
                Text("user.inventory.header \(user.username)")
                    .textStyle(.action200)
                    .foregroundStyle(.foregroundSecondary)
            }
        }
        .navigationTitle("nav.user")
        .sheet(item: $borrowFromItem) { item in
            if let owner = item.owner, let me = userModel.myUser {
                TransactionFormView(
                    transaction: .init(
                        _id: "",
                        _rev: "",
                        item: item,
                        owner: owner,
                        requester: me,
                        type: item.transaction,
                        created: .now,
                        messages: [],
                        state: .requested,
                        actions: [],
                        readStatus: .init(owner: false, requester: true)
                    ),
                    transition: TransactionStateMachine.requestTransition
                )
            }
        }
    }
}

#Preview {
//    UserDetailView()
}
