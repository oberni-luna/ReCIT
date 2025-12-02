//
//  HapticsManager.swift
//  Amata
//
//  Created by Nicolas on 11/03/2024.
//

import UIKit
import CoreHaptics

public final class HapticsManager {
    public enum HapticImpact {
        case primaryButton
        case slider
    }

    public enum HapticAnimation {
        case amataGeneration
        case allowNotificationsButton

        public var loopEnabled: Bool {
            switch self {
            case .amataGeneration:
                true
            case .allowNotificationsButton:
                false
            }
        }
    }

    public static let shared: HapticsManager = .init()

    private var engine: CHHapticEngine?
    private var player: CHHapticAdvancedPatternPlayer?

    private init() {
        loadEngine()
        addObservers()
    }

    public static func play(_ haptic: HapticImpact) {
        switch haptic {
        case .primaryButton:
            primaryButton()
        case .slider:
            slider()
        }
    }

    public static func play(_ haptic: HapticAnimation) {
        switch haptic {
        case .amataGeneration:
            amataGeneration()
        case .allowNotificationsButton:
            allowNotificationsButton()
        }
    }

    public func stop() {
        player?.completionHandler = { _ in }
        try? player?.stop(atTime: 0.0)
        player = nil
    }
}

private extension HapticsManager {
    func loadEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        engine = try? CHHapticEngine()
        try? engine?.start()
    }

    func addObservers() {
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { [weak self] _ in
            self?.engine?.stop()
            self?.engine = nil
        }
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            guard self?.engine == nil else { return }
            self?.loadEngine()
        }
    }
}

// MARK: - Play Haptics impacts -
private extension HapticsManager {
    static func primaryButton() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 1.0)
    }

    static func slider() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.5)
    }
}

// MARK: - Play Haptics animations -
private extension HapticsManager {
    static func amataGeneration() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        shared.player = try? shared.engine?.startPlayingAmata()
    }

    static func allowNotificationsButton() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        shared.player = try? shared.engine?.startPlayingAllowNotifications()
    }
}

// MARK: - Haptic animations code -
private extension CHHapticEngine {
    func startPlayingAmata() throws -> CHHapticAdvancedPatternPlayer {
        let intensity: CHHapticEventParameter = .init(parameterID: .hapticIntensity, value: 1.0)
        let sharpness: CHHapticEventParameter = .init(parameterID: .hapticSharpness, value: 0.4)
        let event: CHHapticEvent = .init(eventType: .hapticContinuous, parameters: [intensity, sharpness], relativeTime: 0.0, duration: 1.0)
        let start: CHHapticParameterCurve.ControlPoint = .init(relativeTime: 0.0, value: 0.2)
        let middle: CHHapticParameterCurve.ControlPoint = .init(relativeTime: 0.5, value: 0.6)
        let end: CHHapticParameterCurve.ControlPoint = .init(relativeTime: 1.0, value: 0.2)
        let parameter: CHHapticParameterCurve = .init(parameterID: .hapticIntensityControl, controlPoints: [start, middle, end], relativeTime: 0.0)
        let pattern: CHHapticPattern = try .init(events: [event], parameterCurves: [parameter])
        let player: CHHapticAdvancedPatternPlayer = try makeAdvancedPlayer(with: pattern)
        player.loopEnabled = true
        try player.start(atTime: 0)
        return player
    }

    func startPlayingAllowNotifications() throws -> CHHapticAdvancedPatternPlayer {
        let intensity: CHHapticEventParameter = .init(parameterID: .hapticIntensity, value: 1.0)
        let sharpness: CHHapticEventParameter = .init(parameterID: .hapticSharpness, value: 0.4)
        let event: CHHapticEvent = .init(eventType: .hapticContinuous, parameters: [intensity, sharpness], relativeTime: 0.0, duration: 1.2)
        let start: CHHapticParameterCurve.ControlPoint = .init(relativeTime: 0.0, value: 0.0)
        let middle: CHHapticParameterCurve.ControlPoint = .init(relativeTime: 0.2, value: 0.6)
        let end: CHHapticParameterCurve.ControlPoint = .init(relativeTime: 0.4, value: 0.0)
        let start2: CHHapticParameterCurve.ControlPoint = .init(relativeTime: 0.6, value: 0.0)
        let middle2: CHHapticParameterCurve.ControlPoint = .init(relativeTime: 0.8, value: 0.6)
        let end2: CHHapticParameterCurve.ControlPoint = .init(relativeTime: 1.0, value: 0.0)
        let parameter: CHHapticParameterCurve = .init(parameterID: .hapticIntensityControl, controlPoints: [start, middle, end, start2, middle2, end2], relativeTime: 0.0)
        let pattern: CHHapticPattern = try .init(events: [event], parameterCurves: [parameter])
        let player: CHHapticAdvancedPatternPlayer = try makeAdvancedPlayer(with: pattern)
        try player.start(atTime: 0)
        return player
    }
}
