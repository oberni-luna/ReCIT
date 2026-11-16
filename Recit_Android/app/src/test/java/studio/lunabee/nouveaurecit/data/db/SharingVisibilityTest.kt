package studio.lunabee.nouveaurecit.data.db

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import studio.lunabee.nouveaurecit.data.model.Visibility

/** iOS `SharingVisibilityTests`: a list or an étagère without a visibility key offers no « Partager ». */
class SharingVisibilityTest {
    @Test
    fun a_list_without_a_visibility_key_is_its_creators_alone() {
        assertTrue(list(emptyList()).isVisibleToCreatorAlone)
        assertFalse(list(listOf(Visibility.Friends)).isVisibleToCreatorAlone)
        assertFalse(list(listOf(Visibility.Groups)).isVisibleToCreatorAlone)
        assertFalse(list(listOf(Visibility.Public)).isVisibleToCreatorAlone)
    }

    @Test
    fun a_shelf_without_a_visibility_key_is_its_owners_alone() {
        assertTrue(shelf(emptyList()).isVisibleToOwnerAlone)
        assertFalse(shelf(listOf(Visibility.Friends)).isVisibleToOwnerAlone)
        assertFalse(shelf(listOf(Visibility.Groups)).isVisibleToOwnerAlone)
        assertFalse(shelf(listOf(Visibility.Public)).isVisibleToOwnerAlone)
    }

    private fun list(visibility: List<Visibility>): EntityListEntity =
        EntityListEntity(id = "list", name = "Livres lus", visibility = visibility)

    private fun shelf(visibility: List<Visibility>): ShelfEntity =
        ShelfEntity(id = "shelf", name = "Polars", ownerId = "me", visibility = visibility)
}
