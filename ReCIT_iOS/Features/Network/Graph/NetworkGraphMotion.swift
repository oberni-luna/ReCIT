//
//  NetworkGraphMotion.swift
//  ReCIT_iOS
//
//  When the Réseau graph moves (PRD 0019, Q17, Q23): never when it opens — it appears already
//  laid out — and never with Reduce Motion on; otherwise, when the network changes, every node
//  slides from its old place to its new one.
//

import SwiftUI

enum NetworkGraphMotion {
    /// The animation a new placement is shown with, or `nil` to show it at once.
    ///
    /// - Parameters:
    ///   - isFirstPlacement: Nothing is placed yet: the graph is opening.
    ///   - reduceMotion: The reader asked for less motion.
    static func animation(
        isFirstPlacement: Bool,
        reduceMotion: Bool
    ) -> Animation? {
        guard isFirstPlacement == false, reduceMotion == false else { return nil }

        return .smooth(duration: NetworkGraphMetrics.transitionDuration)
    }
}
