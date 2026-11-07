package studio.lunabee.nouveaurecit.network

import org.junit.Assert.assertEquals
import org.junit.Test

/** iOS `EnvTests`: the launch argument picks the backend and keeps its session apart. */
class BackendOverrideTest {
    @Test
    fun withoutTheExtraTheAppTalksToInventaireUnderItsUsualSessionStore() {
        assertEquals("https://inventaire.io", BackendOverride.baseUrlFor(null))
        assertEquals("asso.recits.auth.cookies.dev", BackendOverride.sessionStoreNameFor("asso.recits.auth.cookies.dev", null))
    }

    @Test
    fun withTheExtraTheAppTalksToThatBackendUnderASuffixedSessionStore() {
        val backend: String = "http://10.0.2.2:8080"

        assertEquals(backend, BackendOverride.baseUrlFor(backend))
        assertEquals(
            "asso.recits.auth.cookies.dev.exlibris",
            BackendOverride.sessionStoreNameFor("asso.recits.auth.cookies.dev", backend),
        )
    }
}
