package studio.lunabee.nouveaurecit.data.creation

import kotlinx.serialization.json.JsonPrimitive
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import studio.lunabee.nouveaurecit.network.dto.EntityResultDto

/**
 * `WorkCandidateTests`: the line a work is recognised by in the work search — « Kim Stanley Robinson ·
 * 2020 » — asserted on the pure type that composes it.
 */
class WorkCandidateTest {
    private fun hit(uri: String, title: String, description: String? = null) = EntitySearchHit(uri = uri, label = title, description = description)

    @Test
    fun theYearIsReadOffAFullDateAMonthAndABareYear() {
        assertEquals("2020", WorkCandidate.year("2020-10-06"))
        assertEquals("2020", WorkCandidate.year("2020-10"))
        assertEquals("2020", WorkCandidate.year("2020"))
    }

    @Test
    fun aDateBeforeTheCommonEraOrNoDateGivesNoYear() {
        assertNull(WorkCandidate.year("-0500"))
        assertNull(WorkCandidate.year(null))
        assertNull(WorkCandidate.year("19"))
    }

    @Test
    fun authorsAndYearAreJoinedByAMiddleDotAuthorsByAComma() {
        assertEquals("Ursula K. Le Guin · 1969", WorkCandidate.byline(listOf("Ursula K. Le Guin"), "1969"))
        assertEquals("Michel Pinçon, Monique Pinçon-Charlot", WorkCandidate.byline(listOf("Michel Pinçon", "Monique Pinçon-Charlot"), null))
        assertEquals("2019", WorkCandidate.byline(emptyList(), "2019"))
        assertNull(WorkCandidate.byline(emptyList(), null))
    }

    @Test
    fun aWorkIsCompletedByItsAuthorsNamesAndItsYearReadFromTheSameEnvelope() {
        val entities: Map<String, EntityResultDto> = mapOf(
            "wd:Q102036201" to EntityResultDto(
                uri = "wd:Q102036201",
                labels = mapOf("fr" to "Le Ministère du futur"),
                claims = mapOf("wdt:P50" to listOf(JsonPrimitive("wd:Q130779")), "wdt:P577" to listOf(JsonPrimitive("2020-10-06"))),
            ),
            "wd:Q130779" to EntityResultDto(uri = "wd:Q130779", labels = mapOf("fr" to "Kim Stanley Robinson")),
        )

        val candidate: WorkCandidate = WorkCandidate.candidates(listOf(hit("wd:Q102036201", "Le Ministère du futur", "roman")), entities).single()

        assertEquals(listOf("Kim Stanley Robinson"), candidate.authors)
        assertEquals("2020", candidate.year)
        assertEquals("Kim Stanley Robinson · 2020", candidate.detail)
    }

    @Test
    fun aWorkTheEnvelopeSaysNothingAboutKeepsTheSearchsDescription() {
        val candidate: WorkCandidate = WorkCandidate.candidates(listOf(hit("inv:abc", "Ratna krila", "roman d’Erin Morgenstern (2011)")), emptyMap()).single()
        assertEquals("roman d’Erin Morgenstern (2011)", candidate.detail)
    }

    @Test
    fun theSearchsOrderIsKept() {
        assertEquals(listOf("wd:2", "wd:1"), WorkCandidate.candidates(listOf(hit("wd:2", "B"), hit("wd:1", "A")), emptyMap()).map { it.uri })
    }
}
