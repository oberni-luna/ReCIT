//
//  OnboardingScanTallyIllustrationView.swift
//  ReCIT_iOS
//
//  The bilan's illustration: the same plank the accueil shows, this time carrying the user's own
//  books. It is the payoff of the whole sequence — the accueil promised with words over an empty
//  plank, and this is the promise kept with the covers the user has just scanned.
//
//  Its one job is to know *whose* books they are. The books themselves are read from the store by
//  `OnboardingSettlingBooksView`, whose `@Query` predicate needs an owner id at init time — which
//  no view can read from the environment for itself. So the pair splits the way `ShelvesView` and
//  `ShelvesContent` do: this view reads the connected user, the one below it queries.
//
//  The user is read as an optional deliberately, so the plank simply stays bare if there is
//  somehow nobody connected. This is decoration on a screen whose sentence carries the meaning;
//  it is not worth a crash, and it is not worth a placeholder either.
//
//  See PRD 0007, design C2.
//

import SwiftUI

struct OnboardingScanTallyIllustrationView: View {

    /// Optional on purpose — see above. The annotation is what picks the optional lookup, so it
    /// stays even though environments usually do without one.
    @Environment(UserModel.self) private var userModel: UserModel?

    var body: some View {
        OnboardingPlankView {
            if let ownerId = userModel?.myUser?._id {
                OnboardingSettlingBooksView(ownerId: ownerId)
            }
        }
    }
}

#Preview {
    OnboardingScanTallyIllustrationView()
        .padding(.horizontal, .large)
}
