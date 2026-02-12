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
            if let image = user.avatarURLValue {
                CellThumbnail(imageUrl: image, cornerRadius: .full, size: 48)
            }
            VStack(alignment: .leading, spacing: .xSmall) {
                Text(user.username)
                    .font(.headline)
                Text("Item count \(user.itemCount)")
                    .font(.subheadline)
            }
        }
    }
}

