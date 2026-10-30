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
//  Each page scrolls its own way and tells `ProfileScrollOffset` where it is; the header, laid
//  over the pager, folds by the page on screen. Their top is the same on both pages, which is
//  why the étagères are drawn twice: what scrolls with a page has to be in it.
//

import SwiftUI

struct UserProfilePage<Content: View>: View {
    /// Only so the page can hold still while a book is being picked off an étagère.
    @Environment(ShelfFocusModel.self) private var shelfFocus

    let user: User
    let page: UserProfileTab
    /// Their étagères, on the profile of someone whose books are open to me.
    let showsShelves: Bool
    /// Their bio at the top, centred, on the single page of someone who has no Présentation tab.
    let showsBio: Bool
    /// The header's height unfolded — what the page is pushed down by.
    let expandedHeaderHeight: CGFloat
    /// Where the header starts on screen at rest.
    let headerTop: CGFloat?
    let collapse: ProfileHeaderCollapse
    /// Written here, read by the header alone — never by this body, so a scroll redraws the
    /// header only.
    let scrollOffset: ProfileScrollOffset
    @Binding var path: NavigationPath
    @ViewBuilder let content: Content

    /// The scroll view's top inset the offset is counted from, which barely moves.
    @State private var scrollTopInset: CGFloat = 0
    /// Where the list's first row starts on screen at rest: the list puts some room of its own
    /// above its first section, which the first row gives back.
    ///
    /// **Read only while the page is still.** Read whenever the offset said "at rest", it raced
    /// the scroll: a row's new position could arrive before the offset saying the page had
    /// moved, so the first row grew or shrank by that frame's scroll — the page stood still while
    /// the header folded, or sat 40 pt low after a bounce, then jumped back. Read only once, it
    /// caught the screen before the navigation bar had set its insets, and the list rose under
    /// the header. So: whenever the page is at rest (`ProfileScrollOffset.isAtRest`), which
    /// holds through the screen's arrival and never during a gesture or a bounce.
    @State private var firstRowTop: CGFloat?

    /// The list's own room above its first section, once both tops are known.
    private var listTopRoom: CGFloat {
        guard let headerTop, let firstRowTop else { return 0 }
        return firstRowTop - headerTop
    }

    var body: some View {
        List {
            Section {
                // The room the unfolded header takes, as the page's first row rather than a
                // content margin: the scroll's insets are then the bars' alone, and the offset
                // counts from the page at rest whatever the header measures.
                Color.clear
                    .frame(height: max(expandedHeaderHeight - listTopRoom, 0))
                    .onGeometryChange(for: CGFloat.self) { $0.frame(in: .global).minY } action: { top in
                        guard scrollOffset.isAtRest(page) else { return }
                        firstRowTop = top
                    }

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
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

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
            }

            content
        }
        .listStyle(.insetGrouped)
        .environment(\.defaultMinListRowHeight, 0)
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.y + geometry.contentInsets.top
        } action: { _, offset in
            scrollOffset.setOffset(offset, of: page)
        }
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentInsets.top
        } action: { _, inset in
            scrollTopInset = inset
        }
        .onScrollPhaseChange { _, phase in
            scrollOffset.setScrollIdle(phase == .idle, of: page)
        }
        .scrollTargetBehavior(ProfileHeaderSnapBehavior(collapse: collapse, topInset: scrollTopInset))
        .topScrollEdgeEffectHidden()
        .applyListBackground(.backgroundForm)
        // Frozen while a book is being picked off an étagère, so the slide moves the
        // selection and not the page — the same rule the inventory's own carousel follows.
        .scrollDisabled(shelfFocus.isArmed)
    }
}
