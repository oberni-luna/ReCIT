//
//  Haptics.swift
//  Trompet
//
//  Created by Rémi Lanteri on 25/03/2025.
//

import UIKit
import CoreHaptics

public enum Haptics {
    public enum Impact: String, CaseIterable {
        case light
        case medium
        case heavy
        case soft
        case rigid

        private var style: UIImpactFeedbackGenerator.FeedbackStyle {
            switch self {
            case .light:
                .light
            case .medium:
                .medium
            case .heavy:
                .heavy
            case .soft:
                .soft
            case .rigid:
                .rigid
            }
        }

        @MainActor public func play(intensity: CGFloat = 1.0) {
            guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
            UIImpactFeedbackGenerator(style: style).impactOccurred(intensity: intensity)
        }
    }

    public enum Notification: String, CaseIterable {
        case success
        case warning
        case error

        private var type: UINotificationFeedbackGenerator.FeedbackType {
            switch self {
            case .success:
                    .success
            case .warning:
                    .warning
            case .error:
                    .error
            }
        }

        @MainActor public func play() {
            guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
            UINotificationFeedbackGenerator().notificationOccurred(type)
        }
    }
}
