//
//  ProfileDraftTests.swift
//  ReCIT_iOSTests
//
//  What « Modifier le profil » sends. The server answers `400 already up-to-date` to a value it
//  already has and every request costs a second, so the draft must send what changed and nothing
//  else — and, after a refusal part of the way, only what has not landed.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@Suite("ProfileDraft")
struct ProfileDraftTests {

    private func draft(hasPicture: Bool = true) -> ProfileDraft {
        .init(
            username: "OlivierB",
            bio: "Lecteur lent.",
            position: .init(latitude: 45.56789, longitude: 5.91234),
            hasPicture: hasPicture
        )
    }

    @Test("An untouched draft sends nothing and cannot be saved")
    func untouchedSendsNothing() {
        let draft: ProfileDraft = draft()
        #expect(draft.changes.isEmpty)
        #expect(draft.isSaveable == false)
    }

    @Test("Changes go in the form's order: picture, name, bio, position")
    func changesInOrder() {
        var draft: ProfileDraft = draft()
        draft.bio = "Lecteur rapide."
        draft.username = "Olive"
        draft.picture = .replaced(Data([1, 2, 3]))
        draft.place(at: nil)

        #expect(draft.changes == [
            .picture(Data([1, 2, 3])),
            .username("Olive"),
            .bio("Lecteur rapide."),
            .position(nil),
        ])
    }

    @Test("Surrounding whitespace is not a change")
    func whitespaceIsNotAChange() {
        var draft: ProfileDraft = draft()
        draft.username = "  OlivierB "
        draft.bio = "Lecteur lent.\n"
        #expect(draft.changes.isEmpty)
    }

    @Test("Removing a picture there is not is no change")
    func removingNoPicture() {
        var draft: ProfileDraft = draft(hasPicture: false)
        draft.picture = .removed
        #expect(draft.changes.isEmpty)

        var withPicture: ProfileDraft = self.draft(hasPicture: true)
        withPicture.picture = .removed
        #expect(withPicture.changes == [.picture(nil)])
    }

    @Test("A bio past 1 000 characters, or an empty name, cannot be saved")
    func validation() {
        var draft: ProfileDraft = draft()
        draft.bio = String(repeating: "a", count: 1_001)
        #expect(draft.isBioTooLong)
        #expect(draft.isSaveable == false)

        draft.bio = String(repeating: "a", count: 1_000)
        #expect(draft.isSaveable)

        draft.username = "  "
        #expect(draft.isSaveable == false)
    }

    @Test("Only a different name is asked about, not the same one in another case")
    func usernameCheck() {
        var draft: ProfileDraft = draft()
        #expect(draft.usernameNeedsCheck == false)
        draft.username = "olivierb"
        #expect(draft.usernameNeedsCheck == false)
        #expect(draft.changes == [.username("olivierb")])
        draft.username = "Olive"
        #expect(draft.usernameNeedsCheck)
    }

    @Test("A position is rounded to two decimals")
    func positionRounded() {
        var draft: ProfileDraft = draft()
        draft.place(at: .init(latitude: 48.85661, longitude: 2.35222))
        #expect(draft.position == .init(latitude: 48.86, longitude: 2.35))
    }

    @Test("What landed is not sent again")
    func landedIsNotResent() {
        var draft: ProfileDraft = draft()
        draft.picture = .replaced(Data([9]))
        draft.username = "Olive"
        draft.bio = "Autre."

        draft.markLanded([.picture(Data([9])), .username("Olive")])

        #expect(draft.changes == [.bio("Autre.")])
        #expect(draft.showsPicture)
    }
}
