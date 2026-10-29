//
//  EditionLanguageFilterOption.swift
//  ReCIT_iOS
//
//  One entry of the language menu of « Éditions »: a language, and how many editions it holds.
//

import Foundation

nonisolated struct EditionLanguageFilterOption: Equatable, Hashable, Sendable {
    let language: EditionLanguageFilter
    let count: Int
}
