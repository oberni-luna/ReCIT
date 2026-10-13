//
//  AboutInventaireShelf.swift
//  ReCIT_iOS
//
//  The À propos screen's illustration: an étagère as the inventory paints one — wash, books,
//  plank — carrying the user's three latest books, with a paper tag under the plank that names
//  it « inventaire.io ». The shelf the books are on is inventaire.io's, which is the whole point
//  of the screen; the tag says it in the app's own language.
//
//  An illustration, not a shelf: nothing on it answers a press, and VoiceOver skips it — the
//  title under it says what it says.
//
//  Like `OnboardingScanTallyIllustrationView`, its one job is to know *whose* books they are: the
//  query below needs an owner id at init time, which no view can read from the environment for
//  itself. Optional on purpose, so the plank simply stays bare if nobody is connected.
//

import SwiftUI

struct AboutInventaireShelf: View {

    /// Optional on purpose — see above. The annotation is what picks the optional lookup.
    @Environment(UserModel.self) private var userModel: UserModel?

    /// How far the tag's top rides up over the plank's bottom edge — an étagère's own
    /// `ShelfRowView.labelOverlap`, so the tag sits where a shelf's name does.
    private let tagOverlap: CGFloat = 14

    var body: some View {
        VStack(spacing: .zero) {
            OnboardingPlankView {
                if let ownerId = userModel?.myUser?._id {
                    AboutInventaireShelfBooks(ownerId: ownerId)
                }
            }
            AboutInventaireShelfTag()
                .padding(.top, -tagOverlap)
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    AboutInventaireShelf()
        .padding(.horizontal, .medium)
}
