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
                CellThumbnail(imageUrl: image, cornerRadius: .full, size: .large)
            }
            Text(user.username)
                .textStyle(.content400Bold)
                .foregroundStyle(.foregroundDefault)
            UserItemCountText(user: user)
                .textStyle(.content300)
                .foregroundStyle(.foregroundDefault)

            if let bio = user.bio, bio.isEmpty == false {
                Text(bio)
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundSecondary)
            }
        }
    }
}
