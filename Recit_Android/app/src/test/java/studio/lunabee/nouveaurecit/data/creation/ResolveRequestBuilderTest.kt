package studio.lunabee.nouveaurecit.data.creation

import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import studio.lunabee.nouveaurecit.network.ApiService
import studio.lunabee.nouveaurecit.network.dto.EntityResolveRequest

/**
 * `ResolveRequestBuilderTests`: the body that goes on the wire when a book is created. Each rule is one
 * sentence in the builder; each is one assertion here, against the JSON itself where omission matters.
 */
class ResolveRequestBuilderTest {
    private val draft: NewBookDraft = NewBookDraft(
        isbn = "978-2-07-036002-4",
        title = "  La Main gauche de la nuit ",
        authorName = " Ursula K. Le Guin ",
    )

    private fun encoded(request: EntityResolveRequest): JsonObject =
        ApiService.DefaultJson.encodeToJsonElement(EntityResolveRequest.serializer(), request).jsonObject

    @Test
    fun theIsbnTravelsNormalizedWithTheTitleOfThisEdition() {
        val edition: EntityResolveRequest.Seed = ResolveRequestBuilder.request(draft, create = true, language = "fr").entries.single().edition
        assertEquals(listOf("9782070360024"), edition.claims?.get("wdt:P212"))
        assertEquals(listOf("La Main gauche de la nuit"), edition.claims?.get("wdt:P1476"))
    }

    @Test
    fun aNewAuthorAndANewWorkAreDescribedInTheLabelLanguage() {
        val entry: EntityResolveRequest.Entry = ResolveRequestBuilder.request(draft, create = true, language = "en").entries.single()
        assertEquals(mapOf("en" to "Ursula K. Le Guin"), entry.authors?.single()?.labels)
        assertNull(entry.authors?.single()?.uri)
        assertEquals(mapOf("en" to "La Main gauche de la nuit"), entry.works?.single()?.labels)
    }

    @Test
    fun aChosenAuthorIsNamedByUriAndNotDescribed() {
        val chosen: NewBookDraft = draft.copy(authorUri = "wd:Q181659")
        val author: EntityResolveRequest.Seed = ResolveRequestBuilder.request(chosen, create = true, language = "fr").entries.single().authors!!.single()
        assertEquals("wd:Q181659", author.uri)
        assertNull(author.labels)
    }

    @Test
    fun aRecognisedWorkIsPointedAtAndNotSeededAgain() {
        val recognised: NewBookDraft = draft.copy(workUri = "wd:Q1210925")
        val entry: EntityResolveRequest.Entry = ResolveRequestBuilder.request(recognised, create = true, language = "fr").entries.single()
        assertEquals(listOf("wd:Q1210925"), entry.edition.claims?.get("wdt:P629"))
        assertNull(entry.works)
        assertFalse("works" in encoded(ResolveRequestBuilder.request(recognised, create = true, language = "fr"))["entries"]!!.jsonArray[0].jsonObject)
    }

    @Test
    fun theLanguageOfTheIsbnIsClaimedAndNamesTheLabels() {
        val french: NewBookDraft = draft.copy(language = EditionLanguage(uri = "wd:Q150", code = "fr"))
        val entry: EntityResolveRequest.Entry = ResolveRequestBuilder.request(french, create = true, language = "en").entries.single()
        assertEquals(listOf("wd:Q150"), entry.edition.claims?.get("wdt:P407"))
        assertEquals(mapOf("fr" to "Ursula K. Le Guin"), entry.authors?.single()?.labels)
    }

    @Test
    fun noLanguageIsClaimedWhenTheIsbnDidNotSay() {
        val edition: EntityResolveRequest.Seed = ResolveRequestBuilder.request(draft, create = true, language = "fr").entries.single().edition
        assertFalse("wdt:P407" in edition.claims.orEmpty())
    }

    @Test
    fun anUploadedCoverIsOfferedAndAbsentOtherwise() {
        val withCover: NewBookDraft = draft.copy(coverImageUrl = "/img/entities/abc")
        assertEquals("/img/entities/abc", ResolveRequestBuilder.request(withCover, create = true, language = "fr").entries.single().edition.image)

        val edition: JsonObject = encoded(ResolveRequestBuilder.request(draft, create = true, language = "fr"))["entries"]!!.jsonArray[0].jsonObject["edition"]!!.jsonObject
        assertFalse("image" in edition)
        assertFalse("uri" in edition)
        assertFalse("labels" in edition)
    }

    @Test
    fun theDryRunCreatesNothingAndEveryRunIsStrictAndEnriched() {
        val dryRun: JsonObject = encoded(ResolveRequestBuilder.request(draft, create = false, language = "fr"))
        assertEquals("false", dryRun["create"]!!.jsonPrimitive.content)
        assertEquals("true", dryRun["enrich"]!!.jsonPrimitive.content)
        assertEquals("true", dryRun["strict"]!!.jsonPrimitive.content)
        assertTrue(ResolveRequestBuilder.request(draft, create = true, language = "fr").create)
    }

    @Test
    fun aDraftPublishesOnlyWithATitleAndAnAuthor() {
        assertTrue(draft.isPublishable)
        assertFalse(draft.copy(title = "   ").isPublishable)
        assertFalse(draft.copy(authorName = "").isPublishable)
        assertEquals("207036002X", NewBookDraft("2-07-036002-x").normalizedIsbn)
    }
}
