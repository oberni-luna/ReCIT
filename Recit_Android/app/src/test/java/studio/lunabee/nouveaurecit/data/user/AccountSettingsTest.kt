package studio.lunabee.nouveaurecit.data.user

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import studio.lunabee.nouveaurecit.network.ApiService
import studio.lunabee.nouveaurecit.network.dto.UserDto

/** The owner's settings, read from `GET /api/user` the way the server reads them. */
class AccountSettingsTest {
    private fun decoded(json: String): AccountSettings =
        AccountSettings.of(ApiService.DefaultJson.decodeFromString(UserDto.serializer(), json))

    @Test
    fun absentValuesReadAsTheServerReadsThem() {
        val settings: AccountSettings = decoded("""{"_id":"u1","username":"lectrice","email":"l@example.org"}""")

        assertTrue("contributions are anonymous unless set to false", settings.anonymizesContributions)
        assertFalse("off the fediverse until set to true", settings.isFediversable)
        assertFalse("a confirmation nobody mentions is not assumed", settings.isEmailValidated)
        assertEquals("l@example.org", settings.email)
    }

    @Test
    fun anEmptySettingsObjectStillReadsTheSwitchesAsOn() {
        val settings: AccountSettings = decoded("""{"_id":"u1","username":"lectrice","settings":{"notifications":{}}}""")

        assertTrue(settings.anonymizesContributions)
    }

    @Test
    fun valuesTheServerSendsAreTaken() {
        val settings: AccountSettings = decoded(
            """
            {"_id":"u1","username":"lectrice","email":"l@example.org","validEmail":true,"fediversable":true,"language":"fr",
             "settings":{"notifications":{"global":false,"group_invite":true},"contributions":{"anonymize":false}}}
            """.trimIndent(),
        )

        assertEquals(
            AccountSettings(
                userId = "u1",
                email = "l@example.org",
                isEmailValidated = true,
                language = "fr",
                isFediversable = true,
                anonymizesContributions = false,
            )
                .with(NotificationSetting.Global, false)
                .with(NotificationSetting.GroupInvite, true),
            settings,
        )
    }

    @Test
    fun anAbsentNotificationReadsAsOnAndAnAbsentPeriodicityAsTwentyDays() {
        val settings: AccountSettings = decoded(
            """{"_id":"u1","username":"lectrice","settings":{"notifications":{"group_join_request":false,"newsletters":false}}}""",
        )

        assertFalse(settings.isEnabled(NotificationSetting.GroupJoinRequest))
        NotificationSetting.entries.filter { it != NotificationSetting.GroupJoinRequest }.forEach { setting: NotificationSetting ->
            assertTrue("${setting.key} is on until set to false", settings.isEnabled(setting))
        }
        assertEquals(20, settings.summaryPeriodicity)
        assertTrue(decoded("""{"_id":"u1","username":"lectrice"}""").isEnabled(NotificationSetting.Global))
    }

    @Test
    fun theServersPeriodicityIsTaken() {
        assertEquals(7, decoded("""{"_id":"u1","username":"lectrice","summaryPeriodicity":7}""").summaryPeriodicity)
    }

    @Test
    fun theGeneralSwitchOffGreysEveryOtherOneWithoutChangingThem() {
        val settings: AccountSettings = decoded(
            """{"_id":"u1","username":"lectrice","settings":{"notifications":{"global":false,"friendship_request":false}}}""",
        )

        assertTrue("the general switch itself stays editable", settings.canEdit(NotificationSetting.Global))
        NotificationSetting.entries.filter { it != NotificationSetting.Global }.forEach { setting: NotificationSetting ->
            assertFalse("${setting.key} is greyed", settings.canEdit(setting))
        }
        assertFalse(settings.canEditSummaryPeriodicity)
        assertFalse("each keeps its value", settings.isEnabled(NotificationSetting.FriendshipRequest))
        assertTrue(settings.isEnabled(NotificationSetting.GroupInvite))

        val back: AccountSettings = settings.with(NotificationSetting.Global, true)
        assertTrue(NotificationSetting.entries.all { back.canEdit(it) })
        assertTrue(back.canEditSummaryPeriodicity)
    }

    @Test
    fun theFrequencyIsGreyedWhileTheSummaryIsOff() {
        val settings: AccountSettings = decoded(
            """{"_id":"u1","username":"lectrice","settings":{"notifications":{"inventories_activity_summary":false}}}""",
        )

        assertTrue(settings.canEdit(NotificationSetting.InventoriesActivitySummary))
        assertFalse(settings.canEditSummaryPeriodicity)
    }

    @Test
    fun eachNotificationIsItsOwnAttribute() {
        assertEquals(10, NotificationSetting.entries.size)
        assertEquals("settings.notifications.group_acceptRequest", NotificationSetting.GroupAcceptRequest.attribute)
        assertEquals("settings.notifications.global", NotificationSetting.Global.attribute)
    }
}
