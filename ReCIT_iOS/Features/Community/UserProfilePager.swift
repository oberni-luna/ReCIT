//
//  UserProfilePager.swift
//  ReCIT_iOS
//
//  Inventaire and Listes side by side under a reader's profile header, turned by a swipe or by a
//  tab's name — UIKit's own pager, `UIPageViewController`, as the Contacts card of Messages does.
//
//  Two SwiftUI pagers were tried first. A paging `ScrollView` let a finger's slant scroll the
//  page up or down while it turned, and fell back to the first page in one frame. `TabView(.page)`
//  turned by a swipe but not when a tab's name was chosen. UIKit's pager locks the swipe to one
//  direction against the lists it holds, and turns when asked to.
//
//  Each page is a `UIHostingController`, given the screen's environment — the app's models, the
//  store, the navigation — and the safe area by UIKit itself, so its list runs under the bars as
//  any list does. Where the pager stands, 0 on the first page and 1 on the second, is written to
//  `ProfileScrollOffset.pagePosition` as the finger moves, for the header to fold by.
//

import SwiftUI
import UIKit

struct UserProfilePager<Page: View>: UIViewControllerRepresentable {
    @Binding var selection: UserProfileTab
    /// Frozen while a book is being picked off an étagère, like the pages' own scroll.
    let isFrozen: Bool
    let scrollOffset: ProfileScrollOffset
    @ViewBuilder let page: (UserProfileTab) -> Page

    func makeCoordinator() -> Coordinator {
        .init(selection: $selection, scrollOffset: scrollOffset)
    }

    func makeUIViewController(context: Context) -> UIPageViewController {
        let controller: UIPageViewController = .init(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal
        )
        controller.view.backgroundColor = .clear
        controller.dataSource = context.coordinator
        controller.delegate = context.coordinator

        context.coordinator.pages = UserProfileTab.allCases.map { tab in
            let host: UIHostingController<HostedPage> = .init(rootView: hostedPage(tab, context: context))
            host.view.backgroundColor = .clear
            return host
        }
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
        for (tab, host) in zip(UserProfileTab.allCases, coordinator.pages) {
            host.rootView = hostedPage(tab, context: context)
        }
        coordinator.setFrozen(isFrozen)
        coordinator.turn(controller, to: selection)
    }

    private func hostedPage(_ tab: UserProfileTab, context: Context) -> HostedPage {
        .init(content: page(tab), environment: context.environment)
    }

    /// A page with the environment of the screen that holds the pager: a hosting controller
    /// starts from an empty one, which has none of the app's models.
    struct HostedPage: View {
        let content: Page
        let environment: EnvironmentValues

        var body: some View {
            content
                .environment(\.self, environment)
        }
    }

    @MainActor
    final class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        var selection: Binding<UserProfileTab>
        let scrollOffset: ProfileScrollOffset
        var pages: [UIHostingController<HostedPage>] = []

        private weak var controller: UIPageViewController?
        private weak var scrollView: UIScrollView?
        private var offsetObservation: NSKeyValueObservation?
        /// While a tab chosen by its name is being turned to: the pager's own scroll is not a
        /// finger then, and the header is animated to the page instead.
        private var isTurningByName: Bool = false

        init(selection: Binding<UserProfileTab>, scrollOffset: ProfileScrollOffset) {
            self.selection = selection
            self.scrollOffset = scrollOffset
        }

        func page(for tab: UserProfileTab) -> UIHostingController<HostedPage> {
            pages[UserProfileTab.allCases.firstIndex(of: tab) ?? 0]
        }

        private func tab(of viewController: UIViewController?) -> UserProfileTab? {
            guard let index = pages.firstIndex(where: { $0 === viewController }) else { return nil }
            return UserProfileTab.allCases[index]
        }

        /// Reads the finger off the pager's scroll view, which rests with the page on screen in
        /// its middle, one page width in: how far it is from there is how far the swipe has gone.
        func attach(to controller: UIPageViewController) {
            self.controller = controller
            scrollView = controller.view.subviews.lazy.compactMap { $0 as? UIScrollView }.first
            offsetObservation = scrollView?.observe(\.contentOffset, options: [.new]) { [weak self] scrollView, _ in
                MainActor.assumeIsolated {
                    self?.scrolled(scrollView)
                }
            }
        }

        private func scrolled(_ scrollView: UIScrollView) {
            let width: CGFloat = scrollView.bounds.width
            guard isTurningByName == false,
                  width > 0,
                  let shown = tab(of: controller?.viewControllers?.first)
            else { return }

            let swipe: CGFloat = (scrollView.contentOffset.x - width) / width
            let last: CGFloat = ProfileScrollOffset.position(of: UserProfileTab.allCases.last ?? shown)
            scrollOffset.pagePosition = min(max(ProfileScrollOffset.position(of: shown) + swipe, 0), last)
        }

        func setFrozen(_ isFrozen: Bool) {
            scrollView?.isScrollEnabled = isFrozen == false
        }

        /// Turns to the tab chosen by its name, if it is not the page on screen already.
        func turn(_ controller: UIPageViewController, to target: UserProfileTab) {
            guard isTurningByName == false,
                  let shown = tab(of: controller.viewControllers?.first),
                  shown != target
            else { return }

            let isForward: Bool = ProfileScrollOffset.position(of: target) > ProfileScrollOffset.position(of: shown)
            isTurningByName = true
            withAnimation(.snappy) {
                scrollOffset.pagePosition = ProfileScrollOffset.position(of: target)
            }
            controller.setViewControllers(
                [page(for: target)],
                direction: isForward ? .forward : .reverse,
                animated: true
            ) { [weak self] _ in
                self?.isTurningByName = false
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

        /// A swipe that turned the page selects its tab.
        func pageViewController(
            _ pageViewController: UIPageViewController,
            didFinishAnimating finished: Bool,
            previousViewControllers: [UIViewController],
            transitionCompleted completed: Bool
        ) {
            guard let shown = tab(of: pageViewController.viewControllers?.first) else { return }

            scrollOffset.pagePosition = ProfileScrollOffset.position(of: shown)
            if completed, selection.wrappedValue != shown {
                selection.wrappedValue = shown
            }
        }
    }
}
