//
//  TabPager.swift
//  ReCIT_iOS
//
//  A screen's pages side by side, turned by a swipe or by a tab's name — UIKit's own pager,
//  `UIPageViewController`, as the Contacts card of Messages does. A reader's profile holds
//  Inventaire, Listes and Présentation in it; a list's screen, Livres and Présentation.
//
//  Two SwiftUI pagers were tried first. A paging `ScrollView` let a finger's slant scroll the
//  page up or down while it turned, and fell back to the first page in one frame. `TabView(.page)`
//  turned by a swipe but not when a tab's name was chosen. UIKit's pager locks the swipe to one
//  direction against the lists it holds, and turns when asked to. A horizontal scroll view inside
//  a page keeps its own swipe — a list's cover flow scrolls its covers, the rest of the page turns.
//
//  Each page is a `UIHostingController`, given the screen's environment — the app's models, the
//  store, the navigation — and the safe area by UIKit itself, so its list runs under the bars as
//  any list does. Where the pager stands, 0 on the first page, 1 on the second and so on, is
//  written to a `TabPagerPositionStore` as the finger moves, for the tabs (and, on a reader's
//  profile, the header) to follow.
//
//  A page lives in a hosting controller of its own, so a `@FocusState` held by the screen does
//  not reach a field inside it: a page with a text field owns its focus.
//

import SwiftUI
import UIKit

struct TabPager<Tab: CaseIterable & Hashable, Page: View>: UIViewControllerRepresentable {
    /// A page with the environment of the screen that holds the pager: a hosting controller
    /// starts from an empty one, which has none of the app's models.
    ///
    /// The appearance and the text size are the hosting controller's own, read from UIKit's
    /// traits, which follow a change made while the screen is open. The copied environment does
    /// not: switched to dark, the pages stayed light under a header gone white.
    struct HostedPage: View {
        @Environment(\.colorScheme) private var colorScheme
        @Environment(\.dynamicTypeSize) private var dynamicTypeSize

        let content: Page
        let environment: EnvironmentValues

        var body: some View {
            // The nearer the content, the stronger: the two traits go inside the copy, which
            // would otherwise put its own back.
            content
                .environment(\.colorScheme, colorScheme)
                .environment(\.dynamicTypeSize, dynamicTypeSize)
                .environment(\.self, environment)
        }
    }

    @MainActor
    final class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        var selection: Binding<Tab>
        let position: any TabPagerPositionStore
        var tabs: [Tab] = []
        var pages: [UIHostingController<HostedPage>] = []

        private weak var controller: UIPageViewController?
        private weak var scrollView: UIScrollView?
        private var offsetObservation: NSKeyValueObservation?
        /// While a tab chosen by its name is being turned to: the pager's own scroll is not a
        /// finger then, and the position is animated to the page instead.
        private var isTurningByName: Bool = false
        /// Held still by the screen.
        private var isFrozen: Bool = false
        /// A tab chosen by its name while a swipe was still settling: turned to once it has, rather
        /// than lost under the page the swipe lands on.
        private var pendingTab: Tab?

        init(selection: Binding<Tab>, position: any TabPagerPositionStore) {
            self.selection = selection
            self.position = position
        }

        func index(of tab: Tab) -> CGFloat {
            CGFloat(tabs.firstIndex(of: tab) ?? 0)
        }

        func page(for tab: Tab) -> UIHostingController<HostedPage> {
            pages[Int(index(of: tab))]
        }

        private func tab(of viewController: UIViewController?) -> Tab? {
            guard let index = pages.firstIndex(where: { $0 === viewController }) else { return nil }
            return tabs[index]
        }

        /// Reads the finger off the pager's scroll view: where the pages are laid in it says how
        /// far the swipe has gone.
        func attach(to controller: UIPageViewController) {
            self.controller = controller
            scrollView = controller.view.subviews.lazy.compactMap { $0 as? UIScrollView }.first
            offsetObservation = scrollView?.observe(\.contentOffset, options: [.new]) { [weak self] scrollView, _ in
                MainActor.assumeIsolated {
                    self?.scrolled(scrollView)
                }
            }
        }

        /// Measured on the page laid nearest the scroll's offset, not on
        /// `viewControllers.first`: the pager hands that the destination as soon as the finger
        /// lets go, while the offset still counts from the page left — the capsule then jumped
        /// a whole tab until the page had settled.
        private func scrolled(_ scrollView: UIScrollView) {
            let width: CGFloat = scrollView.bounds.width
            guard isTurningByName == false, width > 0 else { return }

            let laidOut: [(index: Int, minX: CGFloat)] = pages.enumerated().compactMap { index, page in
                guard page.isViewLoaded, page.view.isDescendant(of: scrollView) else { return nil }
                return (index, page.view.convert(page.view.bounds, to: scrollView).minX)
            }
            let offset: CGFloat = scrollView.contentOffset.x
            guard let nearest = laidOut.min(by: { abs($0.minX - offset) < abs($1.minX - offset) }) else { return }

            let swiped: CGFloat = CGFloat(nearest.index) + (offset - nearest.minX) / width
            position.pagePosition = min(max(swiped, 0), CGFloat(pages.count - 1))
        }

        func setFrozen(_ isFrozen: Bool) {
            self.isFrozen = isFrozen
            updateScrollEnabled()
        }

        /// No finger on the pages while a tab chosen by its name is turned to: a swipe caught the
        /// turn halfway, UIKit then never reported its end, and the pager waited for it forever —
        /// a tab chosen afterwards did nothing.
        private func updateScrollEnabled() {
            scrollView?.isScrollEnabled = isFrozen == false && isTurningByName == false
        }

        /// Turns to the tab chosen by its name, if it is not the page on screen already.
        func turn(_ controller: UIPageViewController, to target: Tab) {
            guard isTurningByName == false,
                  let shown = tab(of: controller.viewControllers?.first),
                  shown != target
            else { return }

            if let scrollView, scrollView.isDragging || scrollView.isDecelerating {
                pendingTab = target
                return
            }

            let isForward: Bool = index(of: target) > index(of: shown)
            isTurningByName = true
            updateScrollEnabled()
            withAnimation(.snappy) {
                position.pagePosition = index(of: target)
            }
            controller.setViewControllers(
                [page(for: target)],
                direction: isForward ? .forward : .reverse,
                animated: true
            ) { [weak self] _ in
                self?.isTurningByName = false
                self?.updateScrollEnabled()
            }
        }

        // MARK: - UIPageViewControllerDataSource

        func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerBefore viewController: UIViewController
        ) -> UIViewController? {
            guard let index = pages.firstIndex(where: { $0 === viewController }), index > 0 else { return nil }
            return pages[index - 1]
        }

        func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerAfter viewController: UIViewController
        ) -> UIViewController? {
            guard let index = pages.firstIndex(where: { $0 === viewController }), index < pages.count - 1 else {
                return nil
            }
            return pages[index + 1]
        }

        // MARK: - UIPageViewControllerDelegate

        /// A swipe that turned the page selects its tab — unless a tab was chosen by its name
        /// meanwhile, which is turned to now. The selection is the page on screen, whether the
        /// swipe turned it or went back.
        func pageViewController(
            _ pageViewController: UIPageViewController,
            didFinishAnimating finished: Bool,
            previousViewControllers: [UIViewController],
            transitionCompleted completed: Bool
        ) {
            guard let shown = tab(of: pageViewController.viewControllers?.first) else { return }

            position.pagePosition = index(of: shown)
            if let pendingTab {
                self.pendingTab = nil
                if pendingTab != shown {
                    turn(pageViewController, to: pendingTab)
                    return
                }
            }
            if selection.wrappedValue != shown {
                selection.wrappedValue = shown
            }
        }
    }

    @Binding var selection: Tab
    /// The pages' tabs, in their order.
    let tabs: [Tab]
    /// Holds the pages still — while a book is being picked off an étagère, or a comment written.
    let isFrozen: Bool
    let position: any TabPagerPositionStore
    let page: (Tab) -> Page

    init(
        selection: Binding<Tab>,
        tabs: [Tab] = Array(Tab.allCases),
        isFrozen: Bool,
        position: any TabPagerPositionStore,
        @ViewBuilder page: @escaping (Tab) -> Page
    ) {
        _selection = selection
        self.tabs = tabs
        self.isFrozen = isFrozen
        self.position = position
        self.page = page
    }

    func makeCoordinator() -> Coordinator {
        .init(selection: $selection, position: position)
    }

    func makeUIViewController(context: Context) -> UIPageViewController {
        let controller: UIPageViewController = .init(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal
        )
        controller.view.backgroundColor = .clear
        controller.dataSource = context.coordinator
        controller.delegate = context.coordinator

        context.coordinator.tabs = tabs
        context.coordinator.pages = tabs.map { hostingController(for: $0, context: context) }
        controller.setViewControllers(
            [context.coordinator.page(for: selection)],
            direction: .forward,
            animated: false
        )
        context.coordinator.attach(to: controller)
        return controller
    }

    func updateUIViewController(_ controller: UIPageViewController, context: Context) {
        let coordinator: Coordinator = context.coordinator
        coordinator.selection = $selection
        if coordinator.tabs == tabs {
            for (tab, host) in zip(tabs, coordinator.pages) {
                host.rootView = hostedPage(tab, context: context)
            }
        } else {
            // A page added or taken away: the pages are made again, on the selected one.
            coordinator.tabs = tabs
            coordinator.pages = tabs.map { hostingController(for: $0, context: context) }
            controller.setViewControllers(
                [coordinator.page(for: selection)],
                direction: .forward,
                animated: false
            )
        }
        coordinator.setFrozen(isFrozen)
        coordinator.turn(controller, to: selection)
    }

    private func hostingController(for tab: Tab, context: Context) -> UIHostingController<HostedPage> {
        let host: UIHostingController<HostedPage> = .init(rootView: hostedPage(tab, context: context))
        host.view.backgroundColor = .clear
        return host
    }

    private func hostedPage(_ tab: Tab, context: Context) -> HostedPage {
        .init(content: page(tab), environment: context.environment)
    }
}
