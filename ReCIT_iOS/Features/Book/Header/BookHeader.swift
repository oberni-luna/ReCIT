//
//  BookHeader.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 22/11/2026.
//

import SwiftData
import SwiftUI

/// The head of the Fiche livre, held under the navigation bar and folding as the page scrolls, as
/// a reader's profile does. At rest: the cover large and centred over its own blur, the title,
/// the authors and the subtitle, then Présentation | Mon exemplaire | Dans le réseau. Folded: a
/// book row's cover risen into the bar's row, the title on one small line, the tabs still there,
/// over the bars' material once the page passes under it.
///
/// Only the cover and the tabs take touches: the rest lets them through to the page underneath.
struct BookHeader: View {
    private let edition: Edition
    private let tabs: [BookTab]
    private let myUserId: String?
    private let metrics: BookHeaderMetrics
    private let collapse: FoldingHeaderCollapse
    /// Read here and nowhere else on the screen, so a scroll redraws this header only.
    private let scrollOffset: FoldingHeaderScrollOffset<BookTab>
    private let onMeasureTitle: (CGFloat) -> Void
    private let onMeasureByline: (CGFloat) -> Void

    @Binding private var tab: BookTab

    init(
        edition: Edition,
        tab: Binding<BookTab>,
        tabs: [BookTab],
        myUserId: String?,
        metrics: BookHeaderMetrics,
        scrollOffset: FoldingHeaderScrollOffset<BookTab>,
        onMeasureTitle: @escaping (CGFloat) -> Void,
        onMeasureByline: @escaping (CGFloat) -> Void
    ) {
        self.edition = edition
        _tab = tab
        self.tabs = tabs
        self.myUserId = myUserId
        self.metrics = metrics
        collapse = metrics.collapse
        self.scrollOffset = scrollOffset
        self.onMeasureTitle = onMeasureTitle
        self.onMeasureByline = onMeasureByline
    }

    /// Blended between the two pages while the pager moves: each page is scrolled its own way.
    private var progress: CGFloat {
        scrollOffset.progress(in: collapse, among: tabs)
    }

    private var isContentUnder: Bool {
        scrollOffset.isContentUnder(in: collapse, among: tabs)
    }

    /// How far the page is pulled down past its top: the header goes down with it, instead of
    /// staying put while a gap opens under it.
    private var pull: CGFloat {
        scrollOffset.pull(among: tabs)
    }

    var body: some View {
        VStack(spacing: .zero) {
            BookHeaderCover(
                edition.image,
                height: FoldingHeaderCollapse.interpolate(
                    from: BookHeaderMetrics.cover.rest,
                    to: BookHeaderMetrics.cover.folded,
                    progress: progress
                )
            )

            BookHeaderTitle(
                edition.title,
                metrics: metrics,
                progress: progress,
                onMeasure: onMeasureTitle
            )
            .padding(.horizontal, .large)
            .padding(.top, .small)

            BookHeaderByline(
                authorNames: edition.displayedAuthorNames,
                subtitle: edition.subtitle,
                progress: progress,
                height: metrics.bylineHeight,
                onMeasure: onMeasureByline
            )
            .padding(.horizontal, .large)

            BookTabPicker(
                selection: $tab,
                pagePosition: scrollOffset.pagePosition,
                edition: edition,
                myUserId: myUserId
            )
            .padding(.top, .small)
        }
        .padding(.vertical, .small)
        .frame(maxWidth: .infinity)
        .background(alignment: .top) {
            BookHeaderBackdrop(
                imageUrl: edition.image,
                progress: progress,
                isContentUnder: isContentUnder
            )
        }
        // Rising as it folds, so the page under it stays glued to its foot until it is folded.
        .offset(y: pull - BookHeaderMetrics.barRise * progress)
    }
}

#Preview {
    @Previewable @State var tab: BookTab = .presentation

    NavigationStack {
        BookHeader(
            edition: .init(
                uri: "isbn:9782070360024",
                title: "Le Comte de Monte-Cristo",
                subtitle: "Tome I",
                lang: "fr",
                authorNames: ["Alexandre Dumas"]
            ),
            tab: $tab,
            tabs: BookTab.allCases,
            myUserId: "me",
            metrics: .init(dynamicTypeSize: .large, titleHeight: 88, bylineHeight: 30),
            scrollOffset: .init(),
            onMeasureTitle: { _ in },
            onMeasureByline: { _ in }
        )
        Spacer()
    }
    .modelContainer(
        for: [Edition.self, EntityList.self, EntityListItem.self, User.self],
        inMemory: true
    )
}
