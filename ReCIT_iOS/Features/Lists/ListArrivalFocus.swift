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

    var highlightedURI: String? {
        guard case let .highlighted(uri) = phase else { return nil }
        return uri
    }

    /// - Parameter focusURI: The element to arrive on; `nil` for a list opened anywhere else.
    init(focusURI: String?) {
        phase = focusURI.map { .waiting($0) } ?? .done
    }

    /// Starts the arrival the first time the list holds the focused element.
    ///
    /// - Parameters:
    ///   - uris: The list's elements, in order.
    ///   - reduceMotion: Whether the system asks for less motion.
    mutating func start(
        in uris: [String],
        reduceMotion: Bool
    ) {
        guard case let .waiting(uri) = phase, uris.contains(uri) else { return }
        phase = .arriving(reduceMotion ? .jump(uri) : .scroll(uri))
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
