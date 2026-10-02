package studio.lunabee.nouveaurecit.data.book

import kotlinx.serialization.json.JsonPrimitive
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import studio.lunabee.nouveaurecit.network.dto.EntityImageDto
import studio.lunabee.nouveaurecit.network.dto.EntityResultDto
import studio.lunabee.nouveaurecit.network.dto.WikidataProperty

/** `EditionCandidateDTO`'s properties and the resolver's ordering, over hand-built DTOs. */
class EditionCandidatesTest {
    private fun dto(
        uri: String,
        labels: Map<String, String> = emptyMap(),
        titleClaim: String? = null,
        image: String? = null,
        works: Int = 1,
    ): EntityResultDto = EntityResultDto(
        uri = uri,
        originalLang = "fr",
        labels = labels,
        image = image?.let { EntityImageDto(url = it) },
        claims = buildMap {
            if (titleClaim != null) put(WikidataProperty.TITLE, listOf(JsonPrimitive(titleClaim)))
            put(WikidataProperty.EDITION_OF, (1..works).map { JsonPrimitive("wd:Q$it") })
        },
    )

    @Test
    fun titleComesFromLabelsOrTheTitleClaim() {
        assertTrue(EditionCandidates.candidate(dto("a", labels = mapOf("fromclaims" to "Dune")), emptySet()).hasTitle)
        assertTrue(EditionCandidates.candidate(dto("b", titleClaim = "Dune"), emptySet()).hasTitle)
        assertFalse(EditionCandidates.candidate(dto("c", labels = mapOf("fr" to "Dune")), emptySet()).hasTitle)
    }

    @Test
    fun coverNeedsANonEmptyUrl() {
        assertTrue(EditionCandidates.candidate(dto("a", image = "/img/x.jpg"), emptySet()).hasCover)
        assertFalse(EditionCandidates.candidate(dto("b", image = ""), emptySet()).hasCover)
        assertFalse(EditionCandidates.candidate(dto("c"), emptySet()).hasCover)
    }

    @Test
    fun aBoxNamesSeveralWorks() {
        assertTrue(EditionCandidates.candidate(dto("a", works = 1), emptySet()).isSingleWork)
        assertFalse(EditionCandidates.candidate(dto("b", works = 4), emptySet()).isSingleWork)
    }

    @Test
    fun heldComesFromTheGivenSet() {
        assertTrue(EditionCandidates.candidate(dto("a"), setOf("a")).isHeld)
        assertFalse(EditionCandidates.candidate(dto("b"), setOf("a")).isHeld)
    }

    @Test
    fun orderFollowsTheRequestThenASortedTail() {
        val entities: Map<String, EntityResultDto> = mapOf(
            "inv:3" to dto("inv:3"),
            "wd:redirect" to dto("wd:canonical-b"),
            "inv:1" to dto("inv:1"),
            "wd:other" to dto("wd:canonical-a"),
        )
        val ordered: List<String> = EditionCandidates.ordered(listOf("inv:1", "inv:2", "inv:3"), entities).map { it.uri }
        assertEquals(listOf("inv:1", "inv:3", "wd:canonical-a", "wd:canonical-b"), ordered)
    }
}
