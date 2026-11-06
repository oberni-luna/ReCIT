//
//  UserProfileStickyHeader.swift
//  ReCIT_iOS
//
//  The head of a reader's profile, held just under the navigation bar and folding as the page
//  scrolls — the Contacts card of Messages. At rest: their picture at 96 pt, their name large
//  under it, and the Inventaire • 540 | Listes • 4 | Présentation tabs — how many books they hold
//  is in the first tab, no longer a line under the name. Folded: the picture at 48 pt, risen into
//  the bar's row between the back button and « … », the name small under it, the tabs still
//  there. From there on the page scrolls under it, behind the
//  bars' material, which reaches up under the bar, made transparent for it.
//
//  An overlay rather than anything of the bar's: a navigation bar's principal item cannot hold
//  a 96 pt picture. The back button and « … » stay the system's, which keeps the swipe back.
//
//  Only the photo and the tabs take touches: the rest lets them through to the page underneath.
//  The photo opens in the Plein écran, at rest and folded alike.
//
//  See PRD 0031.
//

import SwiftUI

struct UserProfileStickyHeader: View {
    /// What every height of the header is made of, so the screen can know how far the fold
    /// goes before it has happened.
    struct Metrics {
        static let avatar: (rest: CGFloat, folded: CGFloat) = (96, ThumbnailSize.medium.sizeInPt)
        /// How far the folded header rises into the navigation bar: the top of the 48 pt picture
        /// level with the top of the bar's 44 pt buttons, the header's own 8 pt of padding above
        /// it (measured on the phone: 58 left the picture 4 pt lower than the buttons).
        static let barRise: CGFloat = 62

        /// The name's line at rest, in `title200`.
        let nameHeight: CGFloat
        /// What the name is scaled by once folded: down to `title50`, the size of an inline
        /// navigation bar's title, which is what the folded header stands in for.
        let foldedNameScale: CGFloat

        /// Read off the fonts at the text size the screen runs at, so the header's frames hold
        /// its text exactly — no smaller, which would have the text shrink to fit on top of its
        /// scale, and no taller, which would open gaps around it.
        init(dynamicTypeSize: DynamicTypeSize) {
            let name: UIFont = DesignSystem.TextStyle.title200.uiFont(for: dynamicTypeSize)
            let title: UIFont = DesignSystem.TextStyle.title50.uiFont(for: dynamicTypeSize)
            nameHeight = name.lineHeight
            foldedNameScale = title.pointSize / name.pointSize
        }

        var nameScale: (rest: CGFloat, folded: CGFloat) {
            (1, foldedNameScale)
        }

        var collapse: ProfileHeaderCollapse {
            .init(
                distance: (Self.avatar.rest - Self.avatar.folded)
                    + Self.barRise
                    + nameHeight * (1 - foldedNameScale)
            )
        }
    }

    let user: User
    /// `nil` on the profile of someone whose books are closed to me: no tabs to show.
    var tab: Binding<UserProfileTab>?
    /// Where the fetch of their lists stands, for the Listes tab's count.
    let listsLoad: UserListsTab.Load
    let metrics: Metrics
    let collapse: ProfileHeaderCollapse
    /// Read here and nowhere else on the screen, so a scroll redraws this header only.
    let scrollOffset: ProfileScrollOffset

    /// Blended between the two pages while the pager moves: each page is scrolled its own way.
    private var progress: CGFloat {
        scrollOffset.progress(in: collapse)
    }

    private var isContentUnder: Bool {
        scrollOffset.isContentUnder(in: collapse)
    }

    /// How far the page is pulled down past its top — by a finger, or by the bounce of a fling
    /// back up. The header goes down with it, as the Contacts card does, instead of staying put
    /// while a gap opens under it.
    private var pull: CGFloat {
        scrollOffset.pull
    }

    private func folding(_ values: (rest: CGFloat, folded: CGFloat)) -> CGFloat {
        ProfileHeaderCollapse.interpolate(from: values.rest, to: values.folded, progress: progress)
    }

    var body: some View {
        VStack(spacing: .zero) {
            identity

            if let tab {
                UserProfileTabPicker(
                    selection: tab,
                    pagePosition: scrollOffset.pagePosition,
                    user: user,
                    listsLoad: listsLoad
                )
                    .padding(.top, .small)
            }
        }
        .padding(.top, .small)
        .padding(.bottom, .small)
        .frame(maxWidth: .infinity)
        .background(alignment: .top) {
            backdrop
        }
        // Rising as it folds, so the page under it stays glued to its foot until it is folded.
        .offset(y: pull - Metrics.barRise * progress)
    }

    private var identity: some View {
        VStack(spacing: .zero) {
            avatar

            // 8 pt under the picture and over the tabs' 8 pt, at rest and folded alike: the line
            // keeps its own height and is scaled as a whole, in a frame as tall as the scaled
            // line. A long name may still shrink to fit the width, never to fit the height.
            Text(user.username)
                .textStyle(.title200)
                .foregroundStyle(.foregroundDefault)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, .xxLarge)
                .scaleEffect(folding(metrics.nameScale))
                .frame(height: metrics.nameHeight * folding(metrics.nameScale))
                .padding(.top, .small)
                .accessibilityAddTraits(.isHeader)
                .allowsHitTesting(false)
        }
    }

    private var photoURL: URL? {
        user.avatarURLValue.flatMap { URL(string: $0) }
    }

    /// The picture, or the person glyph on a grey disc when there is none: the header keeps its
    /// shape either way.
    @ViewBuilder
    private var avatar: some View {
        let size: CGFloat = folding(Metrics.avatar)
        Group {
            if let photoURL {
                CachedAsyncImage(url: photoURL) { image in
                    image
                        .resizable().scaledToFill()
                } placeholder: {
                    DesignSystem.Color.backgroundDisable.color
                }
            } else {
                Image(systemName: "person")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.foregroundSecondary)
                    .padding(size * 0.28)
                    .background(DesignSystem.Color.backgroundDisable.color)
            }
        }
        .frame(width: size, height: size)
        .clipShape(.circle)
        .thumbnailShadow()
        .accessibilityHidden(true)
        .enlargeablePhoto(photoURL)
        .accessibilityIdentifier(AccessibilityID.photo)
        .allowsHitTesting(photoURL != nil)
    }

    /// Nothing at rest — nothing is behind the header yet. Once the page passes under it, the
    /// bars' own material from the top of the screen down to the header's foot, where it stops
    /// on a hairline, as a navigation bar does.
    private var backdrop: some View {
        Rectangle()
            .fill(.bar)
            .overlay(alignment: .bottom) {
                Divider()
            }
            .opacity(isContentUnder ? 1 : 0)
            .animation(.easeOut(duration: 0.15), value: isContentUnder)
            .ignoresSafeArea(edges: .top)
            .allowsHitTesting(false)
    }
}

private extension UserProfileStickyHeader {
    enum AccessibilityID {
        static let photo: String = "e2e.user.photo"
    }
}
