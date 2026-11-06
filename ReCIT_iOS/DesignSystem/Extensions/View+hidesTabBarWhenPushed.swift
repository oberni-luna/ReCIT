//
//  View+hidesTabBarWhenPushed.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 06/11/2026.
//

import SwiftUI

extension View {
    /// Hides the tab bar, animated, while anything is pushed onto `path` — the way
    /// `hidesBottomBarWhenPushed` does in UIKit. Applied to a tab's `NavigationStack`: set per
    /// destination, the bar snaps instead of moving; `withAnimation` lets it move with the push.
    /// - Parameter path: The stack's path; the tab bar shows only while it is empty.
    func hidesTabBarWhenPushed(on path: NavigationPath) -> some View {
        modifier(TabBarHiddenWhenPushed(isPushed: !path.isEmpty))
    }
}

private struct TabBarHiddenWhenPushed: ViewModifier {
    let isPushed: Bool

    @State private var isTabBarHidden: Bool = false

    func body(content: Content) -> some View {
        content
            .toolbarVisibility(isTabBarHidden ? .hidden : .visible, for: .tabBar)
            .onChange(of: isPushed, initial: true) { _, isPushed in
                withAnimation {
                    isTabBarHidden = isPushed
                }
            }
    }
}
