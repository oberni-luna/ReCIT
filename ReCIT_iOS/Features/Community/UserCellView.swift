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
        HStack(alignment: .top, spacing: .small) {
            CellThumbnail(imageUrl: user.avatarURLValue, cornerRadius: .full, size: 48)

            VStack(alignment: .leading, spacing: .xSmall) {
                Text(user.username)
                    .font(.headline)
                Text("Item count \(user.itemCount)")
                    .font(.subheadline)
            }
        }
    }
}

