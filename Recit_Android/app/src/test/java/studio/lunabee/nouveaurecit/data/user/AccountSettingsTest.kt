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
                email = "l@example.org",
                isEmailValidated = true,
                language = "fr",
                isFediversable = true,
                anonymizesContributions = false,
            ),
            settings,
        )
    }
}
