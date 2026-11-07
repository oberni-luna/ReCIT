package studio.lunabee.exlibris.backend.auth

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

/** Expected digests computed by Node's `crypto`, the way `keygrip` does with inventaire.io's `'sha256', 'base64'`. */
class KeygripTest {
    private val keygrip: Keygrip = Keygrip(listOf("test-secret-new", "test-secret-old"))

    @Test
    fun `signs as Node's keygrip does, in unpadded base64url`() {
        assertEquals(
            "TJn6lEOk0Jk_yNDGdsBlku0LA2ZtDoZv8ad2FR7GqcA",
            keygrip.sign("inventaire:session=${SessionVectors.USER}"),
        )
    }

    @Test
    fun `finds the secret that signed, the newest first`() {
        val data = "inventaire:session=${SessionVectors.USER}"

        assertEquals(0, keygrip.index(data, "TJn6lEOk0Jk_yNDGdsBlku0LA2ZtDoZv8ad2FR7GqcA"))
        assertEquals(1, keygrip.index(data, "1OSiNFTk9x6Z_UOPVQSc_s_k0x1KjBvRWOAr3IQCnWI"))
    }

    @Test
    fun `a digest no secret signed is nobody's`() {
        assertNull(
            keygrip.index("inventaire:session=${SessionVectors.USER}", "TJn6lEOk0Jk_yNDGdsBlku0LA2ZtDoZv8ad2FR7GqcB"),
        )
    }
}
