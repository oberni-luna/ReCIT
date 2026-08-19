//
//  CameraAccess.swift
//  ReCIT_iOS
//
//  The camera permission in the four states AVFoundation actually has, rather than the two
//  a screen is tempted to assume. The distinction that earns this type is `.restricted`
//  versus `.denied`: a restricted camera is held shut by parental controls or a management
//  profile, and the switch the user would be sent to in Settings is not theirs to flip — so
//  the refusal screen must not promise that Settings will fix it.
//
//  `.notDetermined` is transient here on purpose: the flow raises the system prompt itself
//  when it opens rather than letting the camera view raise it on first frame. That is what
//  makes a refusal land on the explanation straight away instead of behind a black feed, and
//  it is why the answer is never read from a stale copy — `current` is re-read every time the
//  app comes back to the foreground.
//
//  See PRD 0005, issue 0020.
//

import AVFoundation

enum CameraAccess: Equatable {
    /// Never asked. The prompt has not been raised yet, or is on screen right now.
    case notDetermined
    case authorized
    /// The user said no, and can say yes again in Settings.
    case denied
    /// Parental controls or an MDM profile. Settings will not help.
    case restricted

    /// The system's answer as of right now. Cheap and synchronous, so the flow can read it
    /// when it opens and again on every return to the foreground.
    static var current: CameraAccess {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: .authorized
        case .denied: .denied
        case .restricted: .restricted
        // On the simulator there is no camera to grant: the scanner view skips AVFoundation
        // entirely and falls back to its simulated barcode. Asking for hardware that does
        // not exist would put a dialog, and then this whole screen, in front of the only way
        // the flow can be exercised there. An explicit refusal is still honoured, on the off
        // chance the simulator ever reports one.
        case .notDetermined: isSimulator ? .authorized : .notDetermined
        // An answer we cannot read is not an answer we can scan with; the explanation is a
        // better landing than a feed that will never arrive.
        @unknown default: .denied
        }
    }

    /// Raises the system prompt if it has never been raised, and reports where that left us.
    /// A plain read on any state that is already settled, so it is safe to call on opening.
    static func request() async -> CameraAccess {
        guard current == .notDetermined else { return current }

        _ = await AVCaptureDevice.requestAccess(for: .video)
        return current
    }

    private static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    /// Whether the live feed can go up. Only an outright yes counts: while the prompt is
    /// still on screen the camera view has to stay down, or it raises a second one behind it.
    var showsCameraFeed: Bool {
        self == .authorized
    }

    /// Whether the screen owes the user an explanation. Not while the prompt is up — the
    /// dialog *is* the explanation, and a second one behind it answers a question the user
    /// has not been asked yet.
    var needsExplanation: Bool {
        self == .denied || self == .restricted
    }

    /// Whether the route into Settings is worth offering, which it is not when the camera is
    /// restricted rather than refused.
    var isRecoverableInSettings: Bool {
        self == .denied
    }
}
