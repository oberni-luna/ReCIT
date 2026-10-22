package studio.lunabee.nouveaurecit.data.creation

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import studio.lunabee.nouveaurecit.network.ApiService
import studio.lunabee.nouveaurecit.network.dto.EntityResolveResponse

/** What `POST /api/entities/resolve` answers, read the two ways the form needs. */
class EntityResolveResponseTest {
    private fun decode(body: String): EntityResolveResponse = ApiService.DefaultJson.decodeFromString(EntityResolveResponse.serializer(), body)

    @Test
    fun aWorkTheServerWouldCreateIsNotARecognisedOne() {
        val response: EntityResolveResponse = decode(
            """{"entries":[{"edition":{"uri":"isbn:9782070360024"},"works":[{"uri":"inv:new","created":true},{"uri":"wd:Q1","resolved":true}]}]}""",
        )
        assertEquals("wd:Q1", response.resolvedWorkUri)
        assertEquals("isbn:9782070360024", response.editionUri)
    }

    @Test
    fun anEmptyAnswerRecognisesNothing() {
        val response: EntityResolveResponse = decode("""{"entries":[]}""")
        assertNull(response.resolvedWorkUri)
        assertNull(response.editionUri)
    }
}
