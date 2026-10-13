//
//  NetworkReaderState.swift
//  ReCIT_iOS
//
//  How a reader stands with me in the Réseau graph: a friend, or someone who asked to be one and
//  waits on my answer — drawn with a dashed ring and a dashed edge (PRD 0019, Q5, Q5b).
//

import Foundation

nonisolated enum NetworkReaderState: Hashable, Sendable {
    case friend
    case requested
}
