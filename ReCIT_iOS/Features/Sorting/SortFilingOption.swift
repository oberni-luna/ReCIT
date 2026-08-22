//
//  SortFilingOption.swift
//  ReCIT_iOS
//
//  One étagère a book can be filed into, as an accessibility action offers it: a name to read
//  out and the section to record the move against.
//
//  It exists because the sorting surface's only gesture is a drag, and a drag does not exist
//  under VoiceOver. Making the screen unusable there would reserve the app's recommended way
//  of filing books to people who can see them — so every book card carries « Ranger dans… »
//  with one option per étagère, recording exactly the change a drop would (PRD 0009).
//

import Foundation

struct SortFilingOption: Identifiable, Equatable, Sendable {
    let sectionId: SortSection.ID
    let name: String

    var id: SortSection.ID { sectionId }
}
