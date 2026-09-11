//
//  UserHeaderView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 09/02/2026.
//
import SwiftUI

struct UserHeaderView: View {
    @Environment(UserModel.self) private var userModel

    let user: User

    /// Whose count the local store can answer for. My own inventory is synced whole and then
    /// kept in step by every add and delete, so counting it locally is both live and exact.
    /// Someone else's is only as complete as what the server let us see, so their header keeps
    /// reading the server's snapshot. Before the first sync lands there is nothing local to
    /// count yet, and the snapshot is the only figure that is not a lie.
    private var countsFromLocalStore: Bool {
        user._id == userModel.myUser?._id && user.lastInventorySync != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .small) {
            if let image = user.avatarURLValue {
                CellThumbnail(imageUrl: image, cornerRadius: .full, size: .large)
            }
            Text(user.username)
                .textStyle(.content400Bold)
                .foregroundStyle(.foregroundDefault)
            Group {
                if countsFromLocalStore {
                    OwnedItemCountText(ownerId: user._id)
                } else {
                    Text("user.item_count \(user.itemCount)")
                }
            }
            .textStyle(.content300)
            .foregroundStyle(.foregroundDefault)
        }
    }
}
