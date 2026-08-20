//
//  AutoSortEntryPoint.swift
//  ReCIT_iOS
//
//  What an entry point to auto-sort should look like, given what Apple Intelligence
//  can currently do. One blanket "unavailable" would be the easy answer and the wrong
//  one: the three reasons differ in what the user can do about them, and the entry
//  point should differ with them. An ineligible device is nothing they can act on, so
//  an explanation buys them only a nag; Apple Intelligence being off is one Settings
//  pane away, so it is worth saying; a model still downloading fixes itself, so it is
//  worth waiting out rather than being told the feature does not exist.
//
//  Deliberately copy-free: this is the decision, not the screen. Two entry points and
//  the flow's own wall all derive their shape from this one mapping, and the wording
//  lives once in `AutoSortUnavailableView` — so a reason cannot be described one way
//  in the settings screen and another way in the flow.
//
//  See PRD 0006.
//

/// The shape an entry point takes for a given availability.
enum AutoSortEntryPoint: Equatable {
    /// Offer it plainly.
    case offered
    /// Show nothing at all. The device cannot run the feature and never will.
    case hidden
    /// Show it, say Apple Intelligence is off, and point at Settings.
    case switchedOff
    /// Show it inert, and say it will work shortly.
    case downloading

    init(availability: AutoSortModel.Availability) {
        switch availability {
        case .available: self = .offered
        case .deviceNotEligible: self = .hidden
        case .appleIntelligenceNotEnabled: self = .switchedOff
        case .modelNotReady: self = .downloading
        }
    }

    /// Whether the entry point appears at all.
    var isVisible: Bool {
        self != .hidden
    }

    /// Whether tapping it can do anything. Only a working model earns a live control:
    /// both visible-but-unavailable cases are shown with their reason instead, which is
    /// the point of showing them.
    var isEnabled: Bool {
        self == .offered
    }

    /// Whether a route to iOS Settings belongs beside it. Only for the reason Settings
    /// can actually fix — the same rule the scanner's permission wall follows.
    var offersSettingsRoute: Bool {
        self == .switchedOff
    }

    /// Whether an entry point that *cannot* be hidden should still lead into the flow.
    /// The empty-state étagère card is the empty state itself, so hiding it is not an
    /// option: on an ineligible device it falls back to the create form — its behaviour
    /// before this existed — and for the two temporary reasons it opens the flow anyway,
    /// where the wall states which one it is. Silently opening a create form there would
    /// answer a question the user never asked.
    var reachesFlow: Bool {
        self != .hidden
    }
}
