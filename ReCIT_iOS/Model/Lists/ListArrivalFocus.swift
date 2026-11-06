//
//  ListArrivalFocus.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 05/11/2026.
//

import Foundation

/// How a list pushed from a book screen arrives on that book: it opens on its first element,
/// moves to the book once the list holds it, then rings its cover until the halo has faded or
/// the reader picks another element. Played once; a list opened without a focus plays nothing.
///
/// One selection haptic per arrival: the cover flow's own, when the selection goes from one
/// element to another; else one as the halo lights (`landingFeedbackURI`).
struct ListArrivalFocus: Equatable {
    /// How the selection reaches the focused element.
    enum Move: Equatable {
        /// A spring through the covers in between.
        case scroll(String)
        /// Straight on it, under Reduce Motion.
        case jump(String)

        var uri: String {
            switch self {
            case let .scroll(uri), let .jump(uri):
                uri
            }
        }
    }

    enum Phase: Equatable {
        /// The list does not hold the focused element yet.
        case waiting(String)
        case arriving(Move)
        case highlighted(String)
        case done
    }

    private(set) var phase: Phase
    /// Whether the arrival moves the selection without the cover flow ticking for it: from no
    /// selection yet, or not at all because the focused element is already selected.
    private var ticksOnLanding: Bool = false

    var highlightedURI: String? {
        guard case let .highlighted(uri) = phase else { return nil }
        return uri
    }

    /// The ringed element, while the halo is the arrival's only haptic.
    var landingFeedbackURI: String? {
        ticksOnLanding ? highlightedURI : nil
    }

    /// - Parameter focusURI: The element to arrive on; `nil` for a list opened anywhere else.
    init(focusURI: String?) {
        phase = focusURI.map { .waiting($0) } ?? .done
    }

    /// Starts the arrival the first time the list holds the focused element.
    ///
    /// A jump sets the selection straight on the focused element; a scroll starts from the
    /// selection, or from the first element the list opens on.
    ///
    /// - Parameters:
    ///   - uris: The list's elements, in order.
    ///   - selectedURI: The selection when the list comes to hold the focused element.
    ///   - reduceMotion: Whether the system asks for less motion.
    /// - Returns: The move just started, `nil` when there is none to make.
    @discardableResult
    mutating func start(
        in uris: [String],
        selectedURI: String?,
        reduceMotion: Bool
    ) -> Move? {
        guard case let .waiting(uri) = phase, uris.contains(uri) else { return nil }
        let origin: String? = reduceMotion ? selectedURI : selectedURI ?? uris.first
        let move: Move = reduceMotion ? .jump(uri) : .scroll(uri)
        ticksOnLanding = origin == nil || origin == uri
        phase = .arriving(move)
        return move
    }

    /// Ends the move: the halo lights if the selection stands on the focused element.
    ///
    /// - Parameter selectedURI: The selection once the move is over.
    mutating func land(on selectedURI: String?) {
        guard case let .arriving(move) = phase else { return }
        phase = selectedURI == move.uri ? .highlighted(move.uri) : .done
    }

    /// Puts the halo out when the reader moves the selection elsewhere.
    ///
    /// - Parameter selectedURI: The new selection.
    mutating func select(_ selectedURI: String?) {
        guard case let .highlighted(uri) = phase, selectedURI != uri else { return }
        phase = .done
    }

    mutating func endHighlight() {
        guard case .highlighted = phase else { return }
        phase = .done
    }
}
