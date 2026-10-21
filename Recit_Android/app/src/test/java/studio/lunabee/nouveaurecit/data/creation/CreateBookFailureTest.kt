package studio.lunabee.nouveaurecit.data.creation

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import studio.lunabee.nouveaurecit.network.NetworkError
import java.io.IOException

/** `CreateBookFailureTests`: which answer gives which sentence, and which one deserves a « Réessayer ». */
class CreateBookFailureTest {
    @Test
    fun anExpiredSessionAsksForAnAccount() {
        assertEquals(CreateBookFailure.NeedsAccount, CreateBookFailure.from(NetworkError.BadStatus(401, "")))
        assertEquals(CreateBookFailure.NeedsAccount, CreateBookFailure.from(NetworkError.BadStatus(403, "")))
    }

    @Test
    fun aRefusedEntryIsNotWorthRetrying() {
        val failure: CreateBookFailure = CreateBookFailure.from(NetworkError.BadStatus(400, "invalid isbn"))
        assertEquals(CreateBookFailure.Refused, failure)
        assertFalse(failure.isWorthRetrying)
        assertFalse(CreateBookFailure.NeedsAccount.isWorthRetrying)
    }

    @Test
    fun everythingElseIsTheCaseARetryIsFor() {
        listOf(
            NetworkError.BadStatus(500, ""),
            NetworkError.BadResponse(),
            NetworkError.Transport(IOException("offline")),
            NetworkError.Decoding(IllegalArgumentException()),
            IllegalStateException(),
        ).forEach { error ->
            assertEquals(CreateBookFailure.Network, CreateBookFailure.from(error))
        }
        assertTrue(CreateBookFailure.Network.isWorthRetrying)
    }
}
