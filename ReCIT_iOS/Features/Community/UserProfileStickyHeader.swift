//
//  UserProfileStickyHeader.swift
//  ReCIT_iOS
//
//  The head of a reader's profile, held just under the navigation bar and folding as the page
//  scrolls — the Contacts card of Messages. At rest: their picture at 96 pt, their name large
//  under it, how many books they hold, and the Inventaire | Listes tabs. Folded: the picture at
//  40 pt, risen into the bar's row between the back button and « … », the name small under it,
//  the count gone, the tabs still there. From there on the page scrolls under it, behind a blur
//  that reaches up under the bar, which is made transparent for it.
//
//  An overlay rather than anything of the bar's: a navigation bar's principal item cannot hold
//  a 96 pt picture. The back button and « … » stay the system's, which keeps the swipe back.
//
//  Only the tabs take touches: the rest lets them through to the page underneath.
//
//  See PRD 0031.
//

import SwiftUI

struct UserProfileStickyHeader: View {
    /// What every height of the header is made of, so the screen can know how far the fold
    /// goes before it has happened.
    struct Metrics {
        static let avatar: (rest: CGFloat, folded: CGFloat) = (96, 40)
        /// How far the folded header rises into the navigation bar: enough for the 40 pt picture
        /// to sit centred on the bar's 44 pt row, the header's own 8 pt of padding above it
        /// (Figma, F3).
        static let barRise: CGFloat = 50

        /// The name's line at rest, in `title200`.
        let nameHeight: CGFloat
        /// What the name is scaled by once folded: down to `title50`, the size of an inline
        /// navigation bar's title, which is what the folded header stands in for.
        let foldedNameScale: CGFloat
        let countHeight: CGFloat

        /// Read off the fonts at the text size the screen runs at, so the header's frames hold
        /// its text exactly — no smaller, which would have the text shrink to fit on top of its
        /// scale, and no taller, which would open gaps around it.
        init(dynamicTypeSize: DynamicTypeSize) {
            let name: UIFont = DesignSystem.TextStyle.title200.uiFont(for: dynamicTypeSize)
            let title: UIFont = DesignSystem.TextStyle.title50.uiFont(for: dynamicTypeSize)
            nameHeight = name.lineHeight
            foldedNameScale = title.pointSize / name.pointSize
            countHeight = DesignSystem.TextStyle.content300.uiFont(for: dynamicTypeSize).lineHeight
        }

        var nameScale: (rest: CGFloat, folded: CGFloat) {
            (1, foldedNameScale)
        }

        var collapse: ProfileHeaderCollapse {
            .init(
                distance: (Self.avatar.rest - Self.avatar.folded)
                    + Self.barRise
                    + nameHeight * (1 - foldedNameScale)
                    + countHeight
                    + DesignSystem.Spacing.xxSmall.rawValue
            )
        }
    }

    let user: User
    /// `nil` on the profile of someone whose books are closed to me: no tabs to show.
    var tab: Binding<UserProfileTab>?
    let metrics: Metrics
    let progress: CGFloat
    let isContentUnder: Bool

    private func folding(_ values: (rest: CGFloat, folded: CGFloat)) -> CGFloat {
        ProfileHeaderCollapse.interpolate(from: values.rest, to: values.folded, progress: progress)
    }

    var body: some View {
        VStack(spacing: .zero) {
            identity
                .allowsHitTesting(false)

            if let tab {
                UserProfileTabPicker(selection: tab)
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
        .offset(y: -Metrics.barRise * progress)
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

            UserItemCountText(user: user)
                .textStyle(.content300)
                .foregroundStyle(.foregroundSecondary)
                .frame(height: metrics.countHeight * (1 - progress))
                .opacity(max(1 - progress * 2, 0))
                .clipped()
                .padding(.top, folding((DesignSystem.Spacing.xxSmall.rawValue, 0)))
        }
    }

    /// The picture, or the person glyph on a grey disc when there is none: the header keeps its
    /// shape either way.
    @ViewBuilder
    private var avatar: some View {
        let size: CGFloat = folding(Metrics.avatar)
        Group {
            if let image = user.avatarURLValue, let url = URL(string: image) {
                CachedAsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
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
    }

    /// Nothing at rest — nothing is behind the header yet. Once the page passes under it, a blur
    /// from the top of the screen, fading out a little below the tabs, and a hairline at its
    /// foot.
    private var backdrop: some View {
        ZStack(alignment: .bottom) {
            VariableBlurView(maxRadius: 20, strongEdge: .top, fadeSpan: 0.25)
                .overlay {
                    LinearGradient(
                        colors: [DesignSystem.Color.backgroundForm.color.opacity(0.8), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .padding(.bottom, -DesignSystem.Spacing.large.rawValue)

            Divider()
        }
        .opacity(isContentUnder ? 1 : 0)
        .animation(.easeOut(duration: 0.2), value: isContentUnder)
        .ignoresSafeArea(edges: .top)
        .allowsHitTesting(false)
    }
}
