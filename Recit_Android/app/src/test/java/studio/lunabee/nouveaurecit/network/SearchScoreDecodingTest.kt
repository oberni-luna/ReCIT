package studio.lunabee.nouveaurecit.network

import org.junit.Assert.assertEquals
import org.junit.Test
import studio.lunabee.nouveaurecit.network.dto.SearchResultsDto

/** `/api/search` sends the score as `_score`: read as `score`, every result scored 0 and the sort did nothing. */
class SearchScoreDecodingTest {
    @Test
    fun the_score_is_read_from_underscore_score() {
        val json = """
            {"results":[
              {"id":"a","type":"works","uri":"wd:Q1","label":"Low","_score":1.5},
              {"id":"b","type":"humans","uri":"wd:Q2","label":"High","_score":9.0}
            ]}
        """.trimIndent()
        val decoded: SearchResultsDto = ApiService.DefaultJson.decodeFromString(SearchResultsDto.serializer(), json)
        assertEquals(listOf(1.5, 9.0), decoded.results.map { it.score })
    }
}
