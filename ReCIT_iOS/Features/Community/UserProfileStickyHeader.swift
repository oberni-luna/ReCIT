//
//  UserProfileStickyHeader.swift
//  ReCIT_iOS
//
//  The head of a reader's profile, held at the top of the screen and folding as the page
//  scrolls — the Contacts card of Messages. At rest: their picture at 96 pt between the back
//  button and « … », their name large under it, how many books they hold, and the Inventaire |
//  Listes tabs. Folded: the picture at 40 pt in the navigation bar's row, the name small, the
//  count gone, the tabs still there. From there on the page scrolls under it, behind a blur.
//
//  **Drawn under the navigation bar, not in it.** A navigation bar is 44 pt tall and its
//  principal item cannot hold a 96 pt picture, so the header is an overlay that starts in the
//  bar's row, and the bar is made transparent above it. The back button and « … » stay the
//  system's, which is what keeps the swipe back working.
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
        static let nameScale: (rest: CGFloat, folded: CGFloat) = (1, 0.6)
        /// How far above the bottom of the navigation bar the header starts: the top of its row
        /// of buttons, give or take the few points between an iOS 18 bar and an iOS 26 one.
        static let barOverlap: CGFloat = 46

        let nameHeight: CGFloat
        let countHeight: CGFloat

        var collapse: ProfileHeaderCollapse {
            .init(
                distance: (Self.avatar.rest - Self.avatar.folded)
                    - 2
                    + nameHeight * (Self.nameScale.rest - Self.nameScale.folded)
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
    /// The status bar and the navigation bar together, which the header reaches up into.
    let topInset: CGFloat

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
        .padding(.top, max(topInset - Metrics.barOverlap, 0))
        .padding(.bottom, .small)
        .frame(maxWidth: .infinity)
        .background(alignment: .top) {
            backdrop
        }
    }

    private var identity: some View {
        VStack(spacing: .zero) {
            avatar
                // Folded, the picture sits centred on the bar's buttons rather than level with
                // their top.
                .padding(.top, folding((0, 2)))

            Text(user.username)
                .textStyle(.title200)
                .foregroundStyle(.foregroundDefault)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.horizontal, .xxLarge)
                .scaleEffect(folding(Metrics.nameScale))
                .frame(height: metrics.nameHeight * folding(Metrics.nameScale))
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
