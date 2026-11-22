//
//  UserProfilePage.swift
//  ReCIT_iOS
//
//  One page of a reader's profile — Inventaire, Listes or Présentation — as an inset grouped
//  `List` of its own: room for the header, their étagères, then the tab's content. The pages
//  sit side by side in a pager, so a tab is changed by a swipe as well as by its name, and the
//  change slides a whole page in instead of having one list swap its sections, which drew the
//  rows sliding and fading under the header.
//
//  Each page is a `FoldingHeaderPage`, which scrolls its own way and tells the header, laid over
//  the pager, where it is. What scrolls with a page has to be in it, which is why the étagères
//  are in the Inventaire page, the only one that shows them.
//

import SwiftUI

struct UserProfilePage<Content: View>: View {
    let user: User
    let layout: FoldingHeaderPageLayout<UserProfileTab>
    /// Their étagères, on the Inventaire page of someone whose books are open to me.
    let showsShelves: Bool
    /// Their bio at the top, centred, on the single page of someone who has no Présentation tab.
    let showsBio: Bool
    /// Rows held to the readable width on a wide screen — every page but an Inventaire laid out
    /// on two columns, which needs the whole width for them.
    let holdsReadableWidth: Bool
    @Binding var path: NavigationPath
    @ViewBuilder let content: Content

    var body: some View {
        FoldingHeaderPage(layout) {
            if showsShelves {
                // Their étagères sit between who they are and what they own, which is the
                // order the two are read in: a shelf says how the library is arranged, the
                // tabs say what is in it.
                Section {
                    UserShelvesSection(user: user, path: $path)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                // Edge to edge, as the inventory's carousel: the inset grouped margins would
                // clip the peeking étagère and the books leaning out of the first one.
                .listSectionHorizontalMargins(0)
            }

            content
        } underHeader: {
            if showsBio, let bio = user.bio, bio.isEmpty == false {
                Text(bio)
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, .medium)
                    .padding(.top, .small)
            }
        }
        .holdsReadableWidth(holdsReadableWidth)
    }
}
