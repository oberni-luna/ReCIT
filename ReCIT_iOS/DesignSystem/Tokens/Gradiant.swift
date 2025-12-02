//
//  Gradiant.swift
// DansMaPoche
//
//  Created by Quentin Noblet on 07/11/2024.
//

import Foundation
import SwiftUI

public extension DesignSystem {
    enum Gradiant {
        case primaryGradient

        public var gradient: LinearGradient {
            switch self {
            case .primaryGradient: .init(
                stops: [.init(color: DesignSystem.Color.surfaceGradientLeft.color, location: 0.43), .init(color: DesignSystem.Color.surfaceGradientRight.color, location: 1)],
                startPoint: .top,
                endPoint: .bottom
            )
            }
        }
    }
}

extension View {
    @inlinable nonisolated public func foregroundStyle(_ style: DesignSystem.Gradiant) -> some View {
        self.foregroundStyle(style.gradient)
    }

    @inlinable nonisolated public func tint(_ tint: DesignSystem.Gradiant) -> some View {
        self.tint(tint.gradient)
    }
}

extension DesignSystem.Gradiant: CaseIterable {}

#Preview {
    Grid {
        ForEach(DesignSystem.Gradiant.allCases, id: \.self) { color in
            Rectangle()
                .frame(width: 64, height: 64)
                .backgroundStyle(color.gradient)
        }
    }
}
