//
//  SearchContent+SearchAttempt.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 16/11/2026.
//

import Foundation

extension SearchContent {
    /// One go at one query. It is the `.task` key, and it holds the attempt count so that
    /// « Réessayer » — which changes nothing about what is being searched for — still reads as
    /// a different call to run.
    struct SearchAttempt: Equatable, Sendable {
        let submission: SearchSuggestion
        let count: Int
    }
}
