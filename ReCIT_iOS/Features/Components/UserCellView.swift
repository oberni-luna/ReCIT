//
//  UserCellView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 16/01/2026.
//

import SwiftUI

struct UserCellView: View {
    let user: User
    let description: String

    var body: some View {
        HStack(alignment: .center, spacing: .small) {
            CellThumbnail(imageUrl: user.avatarURLValue, cornerRadius: .full)
            VStack (alignment: .leading, spacing: .xSmall) {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.textSecondary)
                Text(user.username)
                    .font(.headline)
                    .foregroundStyle(.textDefault)
            }
        }
    }
}

