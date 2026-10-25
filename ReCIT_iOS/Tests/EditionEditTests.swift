//
//  EditionEditTests.swift
//  ReCIT_iOSTests
//
//  What « Modifier l'édition » sends for what the reader changed. Every update names the value
//  it replaces, because `update-claim` replaces nothing it is not told about; and a change half
//  sent is finished by the retry, not sent twice.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@MainActor
@Suite("EditionEdit")
struct EditionEditTests {

    private let hash: String = "75407f010cff3581bd373cc8ada59ad9259bf17a"
    private let newHash: String = "0123456789abcdef0123456789abcdef01234567"

    private func claims(
        title: String = "Lucioles",
        subtitle: String? = "15 fictions pour des futurs écologiques",
        coverHash: String? = "75407f010cff3581bd373cc8ada59ad9259bf17a"
    ) -> EditionClaims {
        .init(
            uri: "inv:69c1353d3d6a4fb21005c0d7367e1eb4",
            title: title,
            subtitle: subtitle,
            coverHash: coverHash,
            isbn: "978-2-37049-300-2"
        )
    }

    @Test("An untouched form has nothing to send")
    func untouchedSendsNothing() {
        let edit: EditionEdit = .init(original: claims(), originalCoverData: Data("cover".utf8))

        #expect(edit.claimUpdates.isEmpty)
        #expect(edit.hasChanges == false)
        #expect(edit.isSaveable == false)
        #expect(edit.coverData == Data("cover".utf8))
    }

    @Test("A new title replaces the old one by name, trimmed")
    func titleNamesTheOldValue() {
        var edit: EditionEdit = .init(original: claims())
        edit.title = "  Lucioles, nouvelle édition  "

        #expect(edit.claimUpdates == [
            .init(
                uri: "inv:69c1353d3d6a4fb21005c0d7367e1eb4",
                property: .title,
                oldValue: "Lucioles",
                newValue: "Lucioles, nouvelle édition"
            )
        ])
        #expect(edit.isSaveable)
    }

    @Test("Spaces added around the title change nothing")
    func whitespaceIsNoChange() {
        var edit: EditionEdit = .init(original: claims())
        edit.title = "Lucioles "

        #expect(edit.claimUpdates.isEmpty)
        #expect(edit.isSaveable == false)
    }

    @Test("A title cannot be emptied")
    func emptyTitleIsNotSaveable() {
        var edit: EditionEdit = .init(original: claims())
        edit.title = "   "

        #expect(edit.hasChanges)
        #expect(edit.isSaveable == false)
    }

    @Test("A subtitle the edition lacked is added; an emptied one is removed")
    func subtitleAddedAndRemoved() {
        var adding: EditionEdit = .init(original: claims(subtitle: nil))
        adding.subtitle = "Tome I"
        #expect(adding.claimUpdates.map(\.property) == [EditableClaimProperty.subtitle.rawValue])
        #expect(adding.claimUpdates.first?.oldValue == nil)
        #expect(adding.claimUpdates.first?.newValue == "Tome I")

        var removing: EditionEdit = .init(original: claims())
        removing.subtitle = ""
        #expect(removing.claimUpdates.first?.oldValue == "15 fictions pour des futurs écologiques")
        #expect(removing.claimUpdates.first?.newValue == nil)
    }

    @Test("A new cover is uploaded first, then hung on the edition in place of the old one")
    func newCoverWaitsForItsHash() {
        var edit: EditionEdit = .init(original: claims())
        edit.coverData = Data("new".utf8)

        #expect(edit.coverToUpload == Data("new".utf8))
        #expect(edit.claimUpdates.isEmpty)
        #expect(edit.isSaveable)

        edit.uploadedCoverHash = newHash

        #expect(edit.coverToUpload == nil)
        #expect(edit.claimUpdates == [
            .init(uri: "inv:69c1353d3d6a4fb21005c0d7367e1eb4", property: .cover, oldValue: hash, newValue: newHash)
        ])
    }

    @Test("Choosing another picture forgets the one already uploaded")
    func anotherPictureForgetsTheUpload() {
        var edit: EditionEdit = .init(original: claims())
        edit.coverData = Data("first".utf8)
        edit.uploadedCoverHash = newHash

        edit.coverData = Data("second".utf8)

        #expect(edit.uploadedCoverHash == nil)
        #expect(edit.coverToUpload == Data("second".utf8))
    }

    @Test("A cover taken away removes the claim; one never there changes nothing")
    func coverRemoved() {
        var edit: EditionEdit = .init(original: claims(), originalCoverData: Data("cover".utf8))
        edit.coverData = nil
        #expect(edit.claimUpdates == [
            .init(uri: "inv:69c1353d3d6a4fb21005c0d7367e1eb4", property: .cover, oldValue: hash, newValue: nil)
        ])

        var bare: EditionEdit = .init(original: claims(coverHash: nil))
        bare.coverData = Data("new".utf8)
        bare.coverData = nil
        #expect(bare.hasChanges == false)
    }

    @Test("What landed is not sent again")
    func landedDropsOut() {
        var edit: EditionEdit = .init(original: claims())
        edit.title = "Lucioles II"
        edit.coverData = Data("new".utf8)
        edit.uploadedCoverHash = newHash

        let title: EditionClaimUpdate = edit.claimUpdates[0]
        edit.landed(title)

        #expect(edit.original.title == "Lucioles II")
        #expect(edit.claimUpdates.map(\.property) == [EditableClaimProperty.cover.rawValue])

        edit.landed(edit.claimUpdates[0])

        #expect(edit.original.coverHash == newHash)
        #expect(edit.originalCoverData == Data("new".utf8))
        #expect(edit.claimUpdates.isEmpty)
        #expect(edit.hasChanges == false)
    }
}
