//
//  NetworkGraphLayout+Crowd.swift
//  ReCIT_iOS
//
//  The friends who share exactly the same groups, as `NetworkGraphLayout` seats them together:
//  how many, and the largest box among them, which sets the room each takes in their rows.
//

import Foundation

extension NetworkGraphLayout {
    nonisolated struct Crowd: Hashable, Sendable {
        private(set) var count: Int = 0
        private(set) var width: Double = 0
        private(set) var height: Double = 0

        mutating func add(_ box: NetworkNodeBox) {
            count += 1
            width = max(width, box.width)
            height = max(height, box.height)
        }
    }
}
