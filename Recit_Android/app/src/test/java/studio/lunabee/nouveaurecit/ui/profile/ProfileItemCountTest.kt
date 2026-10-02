package studio.lunabee.nouveaurecit.ui.profile

import org.junit.Assert.assertEquals
import org.junit.Test
import studio.lunabee.nouveaurecit.data.db.UserEntity

class ProfileItemCountTest {
    @Test
    fun my_count_is_local_once_my_inventory_has_synced() {
        val synced = UserEntity(id = "me", username = "olive", itemCount = 40, lastInventorySync = 1.0)
        assertEquals(37, ProfileViewModel.displayedItemCount(synced, localCount = 37))
    }

    @Test
    fun before_the_first_sync_the_server_snapshot_is_shown() {
        val unsynced = UserEntity(id = "me", username = "olive", itemCount = 40, lastInventorySync = null)
        assertEquals(40, ProfileViewModel.displayedItemCount(unsynced, localCount = 0))
    }
}
