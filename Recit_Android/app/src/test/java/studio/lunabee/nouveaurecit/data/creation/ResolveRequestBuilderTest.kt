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
        authors = listOf(NewBookAuthor(name = " Ursula K. Le Guin ")),
    )

    private val french: EditionLanguage = EditionLanguage(uri = "wd:Q150", code = "fr")

    private fun text(vararg values: String): List<ClaimLiteral> = values.map { ClaimLiteral.Text(it) }

    private fun encoded(request: EntityResolveRequest): JsonObject =
        ApiService.DefaultJson.encodeToJsonElement(EntityResolveRequest.serializer(), request).jsonObject

    private fun entry(draft: NewBookDraft, language: String = "fr"): EntityResolveRequest.Entry =
        ResolveRequestBuilder.request(draft, create = true, language = language).entries.single()

    @Test
    fun theIsbnTravelsNormalizedWithTheTitleOfThisEdition() {
        val edition: EntityResolveRequest.Seed = entry(draft).edition
        assertEquals(text("9782070360024"), edition.claims?.get("wdt:P212"))
        assertEquals(text("La Main gauche de la nuit"), edition.claims?.get("wdt:P1476"))
    }

    @Test
    fun aNewAuthorAndANewWorkAreDescribedInTheLabelLanguage() {
        val entry: EntityResolveRequest.Entry = entry(draft, language = "en")
        assertEquals(mapOf("en" to "Ursula K. Le Guin"), entry.authors?.single()?.labels)
        assertNull(entry.authors?.single()?.uri)
        assertEquals(mapOf("en" to "La Main gauche de la nuit"), entry.works?.single()?.labels)
        assertNull(entry.edition.claims?.get("wdt:P629"))
    }

    @Test
    fun aChosenAuthorIsNamedByUriAndNotDescribed() {
        val chosen: NewBookDraft = draft.copy(authors = listOf(NewBookAuthor(name = "Ursula K. Le Guin", uri = "wd:Q181659")))
        val author: EntityResolveRequest.Seed = entry(chosen).authors!!.single()
        assertEquals("wd:Q181659", author.uri)
        assertNull(author.labels)
    }

    @Test
    fun everyAuthorOfAWorkBeingCreatedIsSentNamedOrDescribedAndABlankRowIsNot() {
        val several: NewBookDraft = draft.copy(
            authors = listOf(
                NewBookAuthor(name = "Michel Pinçon", uri = "wd:Q3311187"),
                NewBookAuthor(name = "Monique Pinçon-Charlot"),
                NewBookAuthor(name = "  "),
            ),
        )
        val authors: List<EntityResolveRequest.Seed> = entry(several).authors!!
        assertEquals(listOf("wd:Q3311187", null), authors.map { it.uri })
        assertEquals(mapOf("fr" to "Monique Pinçon-Charlot"), authors[1].labels)
    }

    @Test
    fun theWorkIsDescribedByItsOwnTitleTheEditionByTheCovers() {
        val draft: NewBookDraft = NewBookDraft(isbn = "9782493373052", authors = listOf(NewBookAuthor(name = "Michael Löwy")))
            .startNewWork("étincelles écosocialistes")
            .copy(title = "Étincelles écosocialistes (poche)")
        val entry: EntityResolveRequest.Entry = entry(draft)
        assertEquals(mapOf("fr" to "Étincelles écosocialistes"), entry.works?.single()?.labels)
        assertEquals(text("Étincelles écosocialistes (poche)"), entry.edition.claims?.get("wdt:P1476"))
    }

    @Test
    fun aKnownWorkIsClaimedAndNamedRatherThanLeftOutAndSendsNoAuthor() {
        val recognised: NewBookDraft = draft.copy(workUri = "wd:Q1210925")
        val entry: EntityResolveRequest.Entry = entry(recognised)
        assertEquals(text("wd:Q1210925"), entry.edition.claims?.get("wdt:P629"))
        assertEquals(listOf(EntityResolveRequest.Seed.named("wd:Q1210925")), entry.works)
        assertNull(entry.authors)
        assertFalse("authors" in encoded(ResolveRequestBuilder.request(recognised, create = true, language = "fr"))["entries"]!!.jsonArray[0].jsonObject)
        // The title typed is the one printed on this cover.
        assertEquals(text("La Main gauche de la nuit"), entry.edition.claims?.get("wdt:P1476"))
    }

    @Test
    fun theLanguageOfTheIsbnIsClaimedAndNamesTheLabels() {
        val entry: EntityResolveRequest.Entry = entry(draft.copy(language = french), language = "en")
        assertEquals(text("wd:Q150"), entry.edition.claims?.get("wdt:P407"))
        assertEquals(mapOf("fr" to "Ursula K. Le Guin"), entry.authors?.single()?.labels)
        assertEquals("fr", entry.works?.single()?.labels?.keys?.single())
    }

    @Test
    fun noLanguageIsClaimedWhenTheIsbnDidNotSay() {
        assertFalse("wdt:P407" in entry(draft).edition.claims.orEmpty())
    }

    @Test
    fun aLanguageChosenInTheFormWinsOverTheIsbns() {
        val chosen: NewBookDraft = draft.copy(language = french).let {
            it.copy(properties = it.properties.add(EditionEntityValue(uri = "wd:Q1860", label = "anglais"), EditionProperty.Language))
        }
        assertEquals(text("wd:Q1860"), entry(chosen).edition.claims?.get("wdt:P407"))
    }

    @Test
    fun anUploadedCoverIsOfferedAndAbsentOtherwise() {
        val withCover: NewBookDraft = draft.copy(coverImageUrl = "https://inventaire.io/img/entities/abc")
        assertEquals("https://inventaire.io/img/entities/abc", entry(withCover).edition.image)

        val edition: JsonObject = encoded(ResolveRequestBuilder.request(draft, create = true, language = "fr"))["entries"]!!
            .jsonArray[0].jsonObject["edition"]!!.jsonObject
        assertFalse("image" in edition)
        assertFalse("uri" in edition)
        assertFalse("labels" in edition)
        assertFalse(encoded(ResolveRequestBuilder.request(draft, create = true, language = "fr")).toString().contains("null"))
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
    fun everyPropertyTravelsInTheEditionSeedCountsAsNumbers() {
        var properties: EditionProperties = EditionProperties()
            .add(EditionEntityValue(uri = "wd:Q336718", label = "Gallimard"), EditionProperty.Publisher)
            .add(EditionEntityValue(uri = "wd:Q1860", label = "anglais"), EditionProperty.Language)
            .setLiteral(ClaimLiteral.Integer(342), EditionProperty.NumberOfPages)
        properties = properties.setLiteral(ClaimLiteral.Text("1971"), EditionProperty.PublicationDateProperty)
        val known: NewBookDraft = draft.copy(workUri = "wd:Q1130619", subtitle = "  roman ", properties = properties)

        val request: EntityResolveRequest = ResolveRequestBuilder.request(known, create = true, language = "fr")
        val claims: Map<String, List<ClaimLiteral>> = request.entries.single().edition.claims!!
        assertEquals(text("roman"), claims["wdt:P1680"])
        assertEquals(text("wd:Q336718"), claims["wdt:P123"])
        assertEquals(text("wd:Q1860"), claims["wdt:P407"])
        assertEquals(listOf(ClaimLiteral.Integer(342)), claims["wdt:P1104"])
        assertEquals(text("1971"), claims["wdt:P577"])
        assertEquals(text("wd:Q1130619"), claims["wdt:P629"])
        assertTrue(encoded(request).toString().contains("\"wdt:P1104\":[342]"))
    }

    @Test
    fun anEntityStillToCreateIsNotNamedInTheSeed() {
        val pending: NewBookDraft = draft.copy(
            workUri = "wd:Q1130619",
            properties = EditionProperties().add(EditionEntityValue(label = "Le Sous-Bois"), EditionProperty.Publisher),
        )
        assertNull(entry(pending).edition.claims?.get("wdt:P123"))
    }

    @Test
    fun aDraftPublishesOnlyWithATitleAndAnAuthor() {
        assertTrue(draft.isPublishable)
        assertFalse(draft.copy(title = "   ").isPublishable)
        assertFalse(draft.copy(authors = emptyList()).isPublishable)
        assertFalse(draft.copy(authors = listOf(NewBookAuthor(name = " "))).isPublishable)
        assertEquals("207036002X", NewBookDraft("2-07-036002-x").normalizedIsbn)
    }
}
