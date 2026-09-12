//
//  UserCellView.swift
//  ReCIT_iOS
//
//  A reader in a list: who they are, and since when.
//
//  Under the name used to sit « N éléments », read from the user's `snapshot`. For a stranger
//  that number is almost always `0` — the snapshot the server serves is of what *I* am allowed
//  to see, and I see nothing of the inventory of someone outside my network. The cell was
//  announcing an empty shelf about readers who own three hundred books. Not a missing figure: a
//  wrong one.
//
//  The date the account was opened is served on the same call, is the same for everyone, and
//  says something true. Missing, it draws nothing rather than falling back on the count it
//  replaced.
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
                if let createdDate = user.createdDate {
                    Text("user.member_since \(createdDate.formatted(.dateTime.month(.wide).year()))")
                        .textStyle(.content300)
                }
            }
            // Left to itself, `List` picks the separator's inset from whatever the row happens
            // to hold, so a row ending in « Ajouter » and a row ending in a tag drew two
            // different lines. Pinned here, every reader row breaks at the username, like the
            // book rows break at the title.
            .alignmentGuide(.listRowSeparatorLeading) { $0[.leading] }
        }
    }
}
