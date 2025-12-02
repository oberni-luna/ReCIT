//
//  CornerRadius.swift
// DansMaPoche
//
//  Created by Olivier Berni on 29/10/2024.
//

import SwiftUI

public extension DesignSystem {
    enum CornerRadius: CGFloat {
        case none = 0
        /// value : 4
        case minimal = 4
        /// value : 8
        case medium = 8
        /// value : 12
        case rounded = 12
        /// value : 24
        case roundedLarge = 24
        /// value : 360
        case full = 360
    }
}

public extension View {
    func cornerRadius(_ radius: DesignSystem.CornerRadius) -> some View {
        cornerRadius(radius.rawValue, antialiased: true)
    }
}

extension RoundedRectangle {
    init(cornerRadius: DesignSystem.CornerRadius) {
        self.init(cornerRadius: cornerRadius.rawValue)
    }
}

extension DesignSystem.CornerRadius: CaseIterable {}

#Preview {
    VStack {
        ForEach(DesignSystem.CornerRadius.allCases, id: \.self) { cornerRadius in
            Rectangle()
                .frame(width: 64, height: 64)
                .cornerRadius(cornerRadius)
        }
    }
    .foregroundStyle(.textDefault)
}
