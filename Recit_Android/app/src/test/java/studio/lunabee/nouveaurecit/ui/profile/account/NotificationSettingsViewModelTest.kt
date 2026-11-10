package studio.lunabee.nouveaurecit.ui.profile.account

import org.junit.Assert.assertEquals
import org.junit.Test

/** The frequencies « Notifications par e-mail » offers in its menu. */
class NotificationSettingsViewModelTest {
    @Test
    fun theMenuOffersItsFrequencies() {
        assertEquals(listOf(1, 7, 14, 20, 30), NotificationSettingsViewModel.periodicities(including = 20))
    }

    @Test
    fun aFrequencyTheWebsiteSetIsAddedInItsPlace() {
        assertEquals(listOf(1, 7, 10, 14, 20, 30), NotificationSettingsViewModel.periodicities(including = 10))
    }
}
