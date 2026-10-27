package studio.lunabee.nouveaurecit.data.creation

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * `EditionEditTests`: what « Modifier l'édition » sends for what the user changed. Every update names the
 * value it replaces, because `update-claim` replaces nothing it is not told about; and a change half sent
 * is finished by the retry, not sent twice.
 */
class EditionEditTest {
    private val uri: String = "inv:69c1353d3d6a4fb21005c0d7367e1eb4"
    private val hash: String = "75407f010cff3581bd373cc8ada59ad9259bf17a"
    private val newHash: String = "0123456789abcdef0123456789abcdef01234567"

    private fun claims(
        title: String = "Lucioles",
        subtitle: String? = "15 fictions pour des futurs écologiques",
        coverHash: String? = hash,
    ): EditionClaims = EditionClaims(
        uri = uri,
        title = title,
        subtitle = subtitle,
        coverHash = coverHash,
        isbn = "978-2-37049-300-2",
        // An edition always names a work: one with none cannot be saved.
        workUris = listOf("inv:work"),
    )

    @Test
    fun anUntouchedFormHasNothingToSend() {
        val edit = EditionEdit(claims())
        assertTrue(edit.claimUpdates.isEmpty())
        assertFalse(edit.hasChanges)
        assertFalse(edit.isSaveable)
        assertNull(edit.nextStep)
        assertEquals("https://inventaire.io/img/entities/$hash", edit.coverUrl)
    }

    @Test
    fun aNewTitleReplacesTheOldOneByNameTrimmed() {
        val edit: EditionEdit = EditionEdit(claims()).copy(title = "  Lucioles, nouvelle édition  ")
        assertEquals(
            listOf(EditionClaimUpdate.of(uri, EditableClaimProperty.Title, "Lucioles", "Lucioles, nouvelle édition")),
            edit.claimUpdates,
        )
        assertTrue(edit.isSaveable)
    }

    @Test
    fun spacesAddedAroundTheTitleChangeNothing() {
        val edit: EditionEdit = EditionEdit(claims()).copy(title = "Lucioles ")
        assertTrue(edit.claimUpdates.isEmpty())
        assertFalse(edit.isSaveable)
    }

    @Test
    fun aTitleCannotBeEmptied() {
        val edit: EditionEdit = EditionEdit(claims()).copy(title = "   ")
        assertTrue(edit.hasChanges)
        assertFalse(edit.isSaveable)
    }

    @Test
    fun aSubtitleTheEditionLackedIsAddedAnEmptiedOneRemoved() {
        val adding: EditionEdit = EditionEdit(claims(subtitle = null)).copy(subtitle = "Tome I")
        assertEquals(listOf(EditableClaimProperty.Subtitle.uri), adding.claimUpdates.map { it.property })
        assertNull(adding.claimUpdates.first().oldValue)
        assertEquals(ClaimLiteral.Text("Tome I"), adding.claimUpdates.first().newValue)

        val removing: EditionEdit = EditionEdit(claims()).copy(subtitle = "")
        assertEquals(ClaimLiteral.Text("15 fictions pour des futurs écologiques"), removing.claimUpdates.first().oldValue)
        assertNull(removing.claimUpdates.first().newValue)
    }

    @Test
    fun aNewCoverIsUploadedFirstThenHungOnTheEditionInPlaceOfTheOldOne() {
        var edit: EditionEdit = EditionEdit(claims()).withCover("/covers/new.jpg")

        assertEquals("/covers/new.jpg", edit.coverToUpload)
        assertEquals(EditionEditStep.UploadCover("/covers/new.jpg"), edit.nextStep)
        assertTrue(edit.claimUpdates.isEmpty())
        assertTrue(edit.isSaveable)
        assertNull(edit.coverUrl)

        edit = edit.coverUploaded(newHash)

        assertNull(edit.coverToUpload)
        assertEquals("/covers/new.jpg", edit.coverPath)
        assertEquals(listOf(EditionClaimUpdate.of(uri, EditableClaimProperty.Cover, hash, newHash)), edit.claimUpdates)
    }

    @Test
    fun choosingAnotherPictureForgetsTheOneAlreadyUploaded() {
        val edit: EditionEdit = EditionEdit(claims()).withCover("/covers/first.jpg").coverUploaded(newHash).withCover("/covers/second.jpg")
        assertNull(edit.uploadedCoverHash)
        assertEquals("/covers/second.jpg", edit.coverToUpload)
    }

    @Test
    fun aCoverTakenAwayRemovesTheClaimOneNeverThereChangesNothing() {
        val removed: EditionEdit = EditionEdit(claims()).withCover(null)
        assertEquals(listOf(EditionClaimUpdate.of(uri, EditableClaimProperty.Cover, hash, null)), removed.claimUpdates)

        val bare: EditionEdit = EditionEdit(claims(coverHash = null)).withCover("/covers/new.jpg").withCover(null)
        assertFalse(bare.hasChanges)
    }

    @Test
    fun whatLandedIsNotSentAgain() {
        var edit: EditionEdit = EditionEdit(claims()).copy(title = "Lucioles II").withCover("/covers/new.jpg").coverUploaded(newHash)

        edit = edit.landed(edit.claimUpdates[0])

        assertEquals("Lucioles II", edit.original.title)
        assertEquals(listOf(EditableClaimProperty.Cover.uri), edit.claimUpdates.map { it.property })

        edit = edit.landed(edit.claimUpdates[0])

        assertEquals(newHash, edit.original.coverHash)
        assertEquals(EditionEdit.Cover.Unchanged, edit.cover)
        assertEquals("https://inventaire.io/img/entities/$newHash", edit.coverUrl)
        assertTrue(edit.claimUpdates.isEmpty())
        assertFalse(edit.hasChanges)
    }

    @Test
    fun aPropertyChangedIsSentAfterTheEditionsOwnClaimsAndLandsByName() {
        val opened = EditionEdit(claims())
        var edit: EditionEdit = opened.copy(
            title = "Lucioles II",
            properties = opened.properties.add(EditionEntityValue(uri = "wd:Q336718", label = "Gallimard"), EditionProperty.Publisher),
        )
        assertEquals(listOf(EditableClaimProperty.Title.uri, "wdt:P123"), edit.claimUpdates.map { it.property })

        edit = edit.landed(edit.claimUpdates[0]).let { it.landed(it.claimUpdates[0]) }

        assertEquals(listOf("Gallimard"), edit.original.properties.entities(EditionProperty.Publisher).map { it.label })
        assertFalse(edit.hasChanges)
    }

    @Test
    fun aCollectionToCreateWithNoPublisherCannotBeSaved() {
        val opened = EditionEdit(EditionClaims(uri = uri, title = "Lucioles", workUris = listOf("inv:work")))
        val edit: EditionEdit = opened.copy(properties = opened.properties.add(EditionEntityValue(label = "Nature writing"), EditionProperty.Collection))
        assertTrue(edit.hasChanges)
        assertFalse(edit.isSaveable)
        // Nothing can be created for it either: no step waits on it.
        assertNull(edit.nextStep)
    }
}
