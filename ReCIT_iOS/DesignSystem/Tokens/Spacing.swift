//
//  Spacing.swift
// DansMaPoche
//
//  Created by Olivier Berni on 29/10/2024.
//
import SwiftUI

public extension DesignSystem {

    enum Spacing: CGFloat, Sendable {
        /// Value : 0
        case zero = 0
        /// Value : 2
        case xxSmall = 2
        /// Value : 4
        case xSmall = 4
        /// Value : 8
        case small = 8
        /// Value : 12
        case sMedium = 12
        /// Value : 16
        case medium = 16
        /// Value : 24
        case large = 24
        /// Value : 32
        case xLarge = 32
        /// Value : 64
        case xxLarge = 64
    }

    enum LineHeight: CGFloat {
        case small = 0.7
        case medium = 0.86
    }
}

// MARK: Usage extensions
public extension View {
    func padding(_ edges: Edge.Set = .all, _ spacing: DesignSystem.Spacing) -> some View {
        padding(edges, spacing.rawValue)
    }
}

extension VStack {
    public init(
        alignment: HorizontalAlignment = .center,
        spacing: DesignSystem.Spacing,
        @ViewBuilder content: () -> Content
    ) {
        self.init(alignment: alignment, spacing: spacing.rawValue, content: content)
    }
}

extension HStack {
    public init(
        alignment: VerticalAlignment = .center,
        spacing: DesignSystem.Spacing,
        @ViewBuilder content: () -> Content
    ) {
        self.init(alignment: alignment, spacing: spacing.rawValue, content: content)
    }
}

extension LazyVStack {
    public init(
        alignment: HorizontalAlignment = .center,
        spacing: DesignSystem.Spacing,
        @ViewBuilder content: () -> Content
    ) {
        self.init(alignment: alignment, spacing: spacing.rawValue, content: content)
    }
}

extension LazyHStack {
    public init(
        alignment: VerticalAlignment = .center,
        spacing: DesignSystem.Spacing,
        @ViewBuilder content: () -> Content
    ) {
        self.init(alignment: alignment, spacing: spacing.rawValue, content: content)
    }
}

extension View {
    public func listRowInsets(top: DesignSystem.Spacing = .zero, leading: DesignSystem.Spacing = .zero, bottom: DesignSystem.Spacing = .zero, trailing: DesignSystem.Spacing = .zero) -> some View {
        listRowInsets(.init(top: top.rawValue, leading: leading.rawValue, bottom: bottom.rawValue, trailing: trailing.rawValue))
    }
}
