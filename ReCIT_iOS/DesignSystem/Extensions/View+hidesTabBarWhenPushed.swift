//
//  View+hidesTabBarWhenPushed.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 06/11/2026.
//
//  Driven by the stack's path, not by each pushed screen: a destination's own
//  `toolbarVisibility(_:for: .tabBar)` snaps the bar away before the push and back after the
//  pop. Changing it inside `withAnimation` as soon as the path leaves or reaches its root lets
//  the bar move with the transition.
//

import SwiftUI

extension View {
    /// Hides the tab bar, animated, while anything is pushed onto `path` — the way
    /// `hidesBottomBarWhenPushed` does in UIKit. Applied to a tab's `NavigationStack`.
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
