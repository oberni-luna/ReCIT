//
//  Array+Split.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 04/12/2025.
//

import Foundation

extension Array {
    func splitInSubArrays(of size: Int) -> [[Element]] {
        let numberOfSubarrays = Int((CGFloat(count)/CGFloat(size)).rounded(.up))
        return (0..<numberOfSubarrays).map {
            return Array(self[$0 * size ... Swift.min(($0 + 1) * size-1, count-1)])
        }
    }
}
