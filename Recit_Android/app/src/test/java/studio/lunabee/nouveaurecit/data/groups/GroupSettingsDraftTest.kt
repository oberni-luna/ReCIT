package studio.lunabee.nouveaurecit.data.groups

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/** What leaving « Réglages du groupe » sends: everything changed on « Enregistrer », nothing when it is closed. */
class GroupSettingsDraftTest {
    private val club: ReaderGroup = group(name = "Club").copy(description = "Le jeudi", pictureUrl = SAVED_URL)
    private val picked: GroupPictureEdit = GroupPictureEdit.Replaced("/cache/covers/cover.jpg")

    @Test
    fun closingTheSheetSendsNothingWhateverWasChanged() {
        val draft: GroupSettingsDraft = GroupSettingsDraft(name = "Polars", description = "Le vendredi", picture = picked)

        assertEquals(GroupSettingsWrites.None, draft.writes(GroupSettingsExit.Dismiss, club))
    }

    @Test
    fun savingSendsEachTrimmedTextThatChangedAndThePickedPhoto() {
        val draft: GroupSettingsDraft = GroupSettingsDraft(name = " Polars ", description = "Le jeudi ", picture = picked)

        val writes: GroupSettingsWrites = draft.writes(GroupSettingsExit.Save, club)

        assertEquals(listOf<GroupSetting>(GroupSetting.Name("Polars")), writes.settings)
        assertEquals(picked, writes.picture)
    }

    @Test
    fun savingSendsNoPhotoWhenTakingAwayOneTheGroupDoesNotHave() {
        val draft: GroupSettingsDraft = GroupSettingsDraft(name = "Club", description = "Le jeudi", picture = GroupPictureEdit.Removed)

        val writes: GroupSettingsWrites = draft.writes(GroupSettingsExit.Save, club.copy(pictureUrl = null))

        assertEquals(GroupSettingsWrites.None, writes)
    }

    @Test
    fun saveIsOfferedOnlyForAChangeWithANameTheServerTakes() {
        assertFalse(GroupSettingsDraft(name = "Club", description = "Le jeudi", picture = GroupPictureEdit.Unchanged).canSave(club))
        assertTrue(GroupSettingsDraft(name = "Club", description = "Le jeudi", picture = GroupPictureEdit.Removed).canSave(club))
        assertTrue(GroupSettingsDraft(name = "Polars", description = "Le jeudi", picture = GroupPictureEdit.Unchanged).canSave(club))
        assertFalse(GroupSettingsDraft(name = "  ", description = "Le jeudi", picture = picked).canSave(club))
    }

    private companion object {
        const val SAVED_URL: String = "https://inventaire.io/img/groups/old"
    }
}
