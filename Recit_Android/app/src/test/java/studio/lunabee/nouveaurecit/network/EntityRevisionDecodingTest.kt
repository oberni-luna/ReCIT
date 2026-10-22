package studio.lunabee.nouveaurecit.network

import org.junit.Assert.assertEquals
import org.junit.Test
import studio.lunabee.nouveaurecit.network.dto.EntityResultsDto

/** Wikidata revision ids passed 2³¹ in 2025: an `Int` failed every book opened from search. */
class EntityRevisionDecodingTest {
    @Test
    fun a_revision_past_two_to_the_thirty_one_decodes() {
        val json = """{"entities":{"wd:Q180736":{"uri":"wd:Q180736","lastrevid":2551707872,"type":"work"}},"redirects":{}}"""
        val decoded: EntityResultsDto = ApiService.DefaultJson.decodeFromString(EntityResultsDto.serializer(), json)
        assertEquals(2_551_707_872L, decoded.entities.getValue("wd:Q180736").lastrevid)
    }
}
