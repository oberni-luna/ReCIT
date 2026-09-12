//
//  UserCellView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 09/02/2026.
//
import SwiftUI

struct UserCellView: View {
    let user: User

    var body: some View {
        HStack(alignment: .top, spacing: .sMedium) {
            CellThumbnail(imageUrl: user.avatarURLValue, cornerRadius: .full, size: .medium)

            VStack(alignment: .leading, spacing: .xSmall) {
                Text(user.username)
                    .textStyle(.content400Bold)
                Text("user.item_count \(user.itemCount)")
                    .textStyle(.content300)
            }
            // Left to itself, `List` picks the separator's inset from whatever the row happens
            // to hold, so a row ending in « Ajouter » and a row ending in a tag drew two
            // different lines. Pinned here, every reader row breaks at the username, like the
            // book rows break at the title.
            .alignmentGuide(.listRowSeparatorLeading) { $0[.leading] }
        }
    }
}
