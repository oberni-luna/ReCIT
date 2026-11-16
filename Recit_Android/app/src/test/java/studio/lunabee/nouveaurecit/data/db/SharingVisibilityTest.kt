package studio.lunabee.nouveaurecit.data.db

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import studio.lunabee.nouveaurecit.data.model.Visibility

/**
 * iOS `SharingVisibilityTests`: a list or an étagère of mine without a visibility key offers no « Partager »; a
 * friend's always does.
 */
class SharingVisibilityTest {
    @Test
    fun a_list_of_mine_without_a_visibility_key_is_not_shareable() {
        assertFalse(list(emptyList()).isShareable(isMine = true))
        assertTrue(list(listOf(Visibility.Friends)).isShareable(isMine = true))
        assertTrue(list(listOf(Visibility.Groups)).isShareable(isMine = true))
        assertTrue(list(listOf(Visibility.Public)).isShareable(isMine = true))
    }

    @Test
    fun a_friends_list_without_a_visibility_key_is_still_shareable() {
        assertTrue(list(emptyList()).isShareable(isMine = false))
    }

    @Test
    fun a_shelf_of_mine_without_a_visibility_key_is_not_shareable() {
        assertFalse(shelf(emptyList()).isShareable(isMine = true))
        assertTrue(shelf(listOf(Visibility.Friends)).isShareable(isMine = true))
        assertTrue(shelf(listOf(Visibility.Groups)).isShareable(isMine = true))
        assertTrue(shelf(listOf(Visibility.Public)).isShareable(isMine = true))
    }

    @Test
    fun a_friends_shelf_without_a_visibility_key_is_still_shareable() {
        assertTrue(shelf(emptyList()).isShareable(isMine = false))
    }

    private fun list(visibility: List<Visibility>): EntityListEntity =
        EntityListEntity(id = "list", name = "Livres lus", visibility = visibility)

    private fun shelf(visibility: List<Visibility>): ShelfEntity =
        ShelfEntity(id = "shelf", name = "Polars", ownerId = "me", visibility = visibility)
}
