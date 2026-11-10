package studio.lunabee.nouveaurecit.data.user

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import studio.lunabee.nouveaurecit.auth.model.FieldAvailability

/** `ProfileDraftTests` (iOS feature 0055): what « Enregistrer » sends, and when it may. */
class ProfileDraftTest {
    private val saved: ProfileDraft.Saved = ProfileDraft.Saved(
        username = "lectrice",
        bio = "Romans noirs",
        position = Coordinates(45.57, 5.92),
        hasPicture = true,
    )
    private val draft: ProfileDraft = ProfileDraft(saved)

    @Test
    fun anUntouchedDraftSendsNothingAndCannotBeSaved() {
        assertEquals(emptyList<ProfileChange>(), draft.changes)
        assertFalse(draft.isSaveable)
    }

    @Test
    fun changesComeInTheFormsOrderPictureUsernameBioPosition() {
        val edited: ProfileDraft = draft
            .placed(Coordinates(48.85, 2.35))
            .copy(bio = "Polars", username = "liseuse", picture = ProfileDraft.Picture.Replaced("/cache/covers/a.jpg"))

        assertEquals(
            listOf(
                ProfileChange.Picture("/cache/covers/a.jpg"),
                ProfileChange.Username("liseuse"),
                ProfileChange.Bio("Polars"),
                ProfileChange.Position(Coordinates(48.85, 2.35)),
            ),
            edited.changes,
        )
    }

    @Test
    fun textIsSentTrimmedAndOnlyWhenItMoved() {
        assertEquals(emptyList<ProfileChange>(), draft.copy(username = " lectrice ", bio = "Romans noirs\n").changes)
        assertEquals(listOf(ProfileChange.Bio("Polars")), draft.copy(bio = "  Polars ").changes)
    }

    @Test
    fun removingAPictureIsAChangeOnlyWhenTheAccountHasOne() {
        assertEquals(listOf(ProfileChange.Picture(null)), draft.copy(picture = ProfileDraft.Picture.Removed).changes)

        val withoutPicture: ProfileDraft = ProfileDraft(saved.copy(hasPicture = false), picture = ProfileDraft.Picture.Removed)
        assertEquals(emptyList<ProfileChange>(), withoutPicture.changes)
        assertFalse(withoutPicture.showsPicture)
    }

    @Test
    fun aBioPastAThousandCharactersCannotBeSaved() {
        val atLimit: ProfileDraft = draft.copy(bio = "a".repeat(ProfileDraft.BIO_LIMIT))
        val past: ProfileDraft = draft.copy(bio = "a".repeat(ProfileDraft.BIO_LIMIT + 1))

        assertTrue(atLimit.isSaveable)
        assertTrue(past.isBioTooLong)
        assertEquals(1_001, past.bioLength)
        assertFalse(past.isSaveable)
    }

    @Test
    fun anEmptyUsernameCannotBeSaved() {
        val empty: ProfileDraft = draft.copy(username = "   ", bio = "Polars")

        assertTrue(empty.isUsernameEmpty)
        assertFalse(empty.isSaveable)
    }

    @Test
    fun aUsernameTheLiveCheckRefusesCannotBeSaved() {
        val renamed: ProfileDraft = draft.copy(username = "x")
        val check: FieldAvailability = FieldAvailability(FieldAvailability.Field.Username).edited("x")

        assertTrue(renamed.canSave(check))
        assertFalse(renamed.canSave(check.apply(FieldAvailability.Outcome.Invalid, "x")))
        assertFalse(renamed.canSave(check.apply(FieldAvailability.Outcome.Taken, "x")))
        assertTrue(renamed.canSave(check.apply(FieldAvailability.Outcome.Available, "x")))
    }

    @Test
    fun theAccountsOwnNameInAnotherCaseIsNeverAskedAbout() {
        val recased: ProfileDraft = draft.copy(username = "Lectrice")
        val refused: FieldAvailability = FieldAvailability(FieldAvailability.Field.Username).edited("Lectrice")
            .apply(FieldAvailability.Outcome.Taken, "Lectrice")

        assertFalse(recased.usernameNeedsCheck)
        assertEquals(listOf(ProfileChange.Username("Lectrice")), recased.changes)
        assertTrue(recased.canSave(refused))
    }

    @Test
    fun aPositionIsRoundedToTwoDecimals() {
        assertEquals(Coordinates(45.57, 5.92), draft.placed(Coordinates(45.566_8, 5.917_4)).position)
        assertEquals(Coordinates(-33.87, -151.21), draft.placed(Coordinates(-33.868_8, -151.209_3)).position)
        assertEquals(Coordinates(0.13, -0.13), ProfileDraft.rounded(Coordinates(0.125, -0.125)))
    }

    @Test
    fun placingNothingTakesThePositionAway() {
        assertEquals(listOf(ProfileChange.Position(null)), draft.placed(null).changes)
    }

    @Test
    fun whatLandedIsNotSentAgain() {
        val edited: ProfileDraft = draft.copy(picture = ProfileDraft.Picture.Replaced("/a.jpg"), bio = "Polars")
            .placed(Coordinates(48.85, 2.35))

        val retried: ProfileDraft = edited.markLanded(listOf(ProfileChange.Picture("/a.jpg")))

        assertEquals(listOf(ProfileChange.Bio("Polars"), ProfileChange.Position(Coordinates(48.85, 2.35))), retried.changes)
        assertEquals(ProfileDraft.Picture.Unchanged, retried.picture)
        assertTrue(retried.showsPicture)
    }

    @Test
    fun aRemovedPictureThatLandedLeavesNothingToRemove() {
        val landed: ProfileDraft = draft.copy(picture = ProfileDraft.Picture.Removed).markLanded(listOf(ProfileChange.Picture(null)))

        assertFalse(landed.saved.hasPicture)
        assertFalse(landed.showsPicture)
        assertEquals(emptyList<ProfileChange>(), landed.copy(picture = ProfileDraft.Picture.Removed).changes)
    }
}
