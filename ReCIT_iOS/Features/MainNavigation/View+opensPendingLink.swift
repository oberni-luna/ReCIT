//
//  View+opensPendingLink.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 16/11/2026.
//

import SwiftUI

extension View {
    /// Pushes the screen an Ex-libris link asked of `tab`, alone above the root of the stack `path`
    /// drives. Applied to a tab's `NavigationStack`, which takes only the links naming its tab.
    /// - Parameters:
    ///   - tab: The tab this stack belongs to.
    ///   - path: The stack's path, emptied before the screen is pushed.
    func opensPendingLink(
        on tab: MainTabView.TabConfig,
        path: Binding<NavigationPath>
    ) -> some View {
        modifier(PendingLinkOpening(tab: tab, path: path))
    }
}

private struct PendingLinkOpening: ViewModifier {
    let tab: MainTabView.TabConfig

    @Binding var path: NavigationPath

    @Environment(TabRouter.self) private var router: TabRouter

    func body(content: Content) -> some View {
        content
            // On appearing as well as on change: the link is usually what builds the tab, and it
            // is already waiting by the time the tab exists to see it.
            .onAppear(perform: openLinkIfAsked)
            .onChange(of: router.pendingLink) { _, link in
                if link != nil {
                    openLinkIfAsked()
                }
            }
    }

    private func openLinkIfAsked() {
        guard let destination = router.consumePendingLink(for: tab) else { return }
        path = .init()
        path.append(destination)
    }
}
