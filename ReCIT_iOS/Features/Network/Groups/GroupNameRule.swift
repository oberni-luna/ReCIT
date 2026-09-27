//
//  GroupNameRule.swift
//  ReCIT_iOS
//
//  What inventaire.io accepts as a group name (`server/models/validations/group.ts`): 1 to 80
//  characters once trimmed. Checked as the name is typed, so the form never sends one the server
//  will refuse.
//

import Foundation

enum GroupNameRule {
    static let maximumLength: Int = 80

    static func accepts(_ name: String) -> Bool {
        let trimmed: String = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty == false && trimmed.count <= maximumLength
    }
}
