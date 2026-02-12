//
//  UserHeaderView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 09/02/2026.
//
import SwiftUI

struct UserHeaderView: View {
    let user: User

    var body: some View {
        VStack(alignment: .leading, spacing: .small) {
            if let image = user.avatarURLValue {
                CellThumbnail(imageUrl: image, cornerRadius: .full, size: 72)
            }
            Text(user.username)
                .font(.headline)
            Text("Item count \(user.itemCount)")
                .font(.subheadline)
        }
    }
}

