//
//  DuplicatesReviewSummary.swift
//  ReCIT_iOS
//
//  What a review of duplicates did, counted as it goes and said in one SnackBar on the way back
//  to « Éditions »: how many pairs were merged, how many reported to inventaire.io's team.
//  Declaring a pair different is not counted — the pair leaving the list says it. PRD 0028.
//

import Foundation

struct DuplicatesReviewSummary: Equatable {
    private(set) var merged: Int = 0
    private(set) var reported: Int = 0

    mutating func record(_ outcome: MergeOutcome) {
        switch outcome {
        case .merged:
            merged += 1
        case .reported:
            reported += 1
        }
    }

    /// The SnackBar's sentence, `nil` when nothing was sent.
    var message: String? {
        let parts: [String] = [
            merged > 0 ? String(localized: "duplicates.summary.merged \(merged)") : nil,
            reported > 0 ? String(localized: "duplicates.summary.reported \(reported)") : nil
        ].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " ")
    }
}
