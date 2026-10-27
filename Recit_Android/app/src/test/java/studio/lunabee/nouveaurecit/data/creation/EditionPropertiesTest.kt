package studio.lunabee.nouveaurecit.data.creation

import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonPrimitive
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import studio.lunabee.nouveaurecit.network.ApiService

/**
 * `EditionPropertiesTests`: the catalogue of an edition's properties and the values the form holds for
 * them — what is read from `by-uris`, what a typed identifier becomes, and which claims a change comes to:
 * one update naming the value it replaces for a single value, one per value added or taken away for several.
 */
class EditionPropertiesTest {
    private val editionUri: String = "inv:edition"
    private val gallimard: EditionEntityValue = EditionEntityValue(uri = "wd:Q336718", label = "Gallimard")
    private val bnf: EditionProperty = EditionProperty.named("wdt:P268")!!

    private fun text(value: String): ClaimLiteral = ClaimLiteral.Text(value)

    // The catalogue

    @Test
    fun everyPropertyOfTheCatalogueIsNamedOnce() {
        val uris: List<String> = EditionProperty.all.map { it.uri }
        assertEquals(uris.size, uris.toSet().size)
        assertEquals(22, EditionProperty.databases.size)
        assertEquals(10, EditionProperty.links.size)
        assertEquals(6, EditionProperty.contributors.size)
        assertNull(EditionProperty.named("wdt:P212"))
        assertNull(EditionProperty.named("wdt:P1889"))
        assertEquals(4, EditionProperty.inGroup(EditionProperty.Group.Publication).size)
        assertEquals(3, EditionProperty.inGroup(EditionProperty.Group.Format).size)
    }

    @Test
    fun anIdentifierIsCheckedAgainstTheServersPatternAfterItsSmallRewrites() {
        assertEquals(text("123735831"), bnf.literal("cb123735831"))
        assertEquals(text("123735831"), bnf.literal(" 123735831 "))
        assertNull(bnf.literal("12373583"))

        val openLibrary: EditionProperty = EditionProperty.named("wdt:P648")!!
        assertEquals(text("OL61173905M"), openLibrary.literal("OL61173905M"))
        // A work's identifier is not an edition's.
        assertNull(openLibrary.literal("OL36858W"))

        assertEquals(text("jz@mamot.fr"), EditionProperty.named("wdt:P4033")!!.literal("@jz@mamot.fr"))
        assertNotNull(EditionProperty.named("wdt:P356")!!.literal("10.1371/journal.pone.0029797"))
    }

    @Test
    fun everyExampleTheServerGivesPassesItsOwnPattern() {
        for (property in EditionProperty.databases + EditionProperty.links) {
            val kind: EditionProperty.Kind.Identifier = property.kind as? EditionProperty.Kind.Identifier ?: continue
            assertNotNull("${property.uri} refuses ${kind.example}", property.literal(kind.example))
            assertEquals(kind.example, property.example)
        }
    }

    @Test
    fun aCountIsAPositiveNumberALinkAnHttpAddressADateOneOfThreeShapes() {
        assertEquals(ClaimLiteral.Integer(256), EditionProperty.NumberOfPages.literal("256"))
        assertNull(EditionProperty.NumberOfPages.literal("0"))
        assertNull(EditionProperty.NumberOfPages.literal(""))

        val website: EditionProperty = EditionProperty.named("wdt:P856")!!
        assertEquals(text("https://www.gallimard.fr"), website.literal("https://www.gallimard.fr"))
        assertNull(website.literal("gallimard.fr"))
        assertNull(website.literal("ftp://gallimard.fr"))
        assertEquals("https://", website.example)

        assertEquals(text("2023-03"), EditionProperty.PublicationDateProperty.literal("2023-3"))
        assertNull(EditionProperty.PublicationDateProperty.literal("mars 2023"))
    }

    @Test
    fun onlyPeoplePublishersAndCollectionsCanBeCreated() {
        assertTrue(EditionProperty.Publisher.allowsCreation)
        assertTrue(EditionProperty.Collection.allowsCreation)
        assertTrue(EditionProperty.contributors.all { it.allowsCreation })
        assertFalse(EditionProperty.Language.allowsCreation)
        assertEquals(EntityCreationKind.Collection("wd:Q1"), EntityCreationKind.of(EditionProperty.Collection, "wd:Q1"))
        assertNull(EntityCreationKind.of(EditionProperty.Collection, null))
        assertNull(EntityCreationKind.of(EditionProperty.Language, "wd:Q1"))
        assertEquals(EntityCreationKind.Human, EntityCreationKind.of(EditionProperty.contributors[0], null))
    }

    // Reading

    @Test
    fun valuesAreReadFromTheClaimsEntitiesNamedCountsKeptAsNumbers() {
        val claims: Map<String, List<JsonElement>> = mapOf(
            "wdt:P123" to listOf(JsonPrimitive("wd:Q336718")),
            "wdt:P407" to listOf(JsonPrimitive("wd:Q150")),
            "wdt:P1104" to listOf(JsonPrimitive(256)),
            "wdt:P577" to listOf(JsonPrimitive("2023-03")),
            "wdt:P268" to listOf(JsonPrimitive("123735831")),
            "wdt:P212" to listOf(JsonPrimitive("978-2-07-036822-8")),
        )
        val properties: EditionProperties = EditionProperties.fromClaims(claims, mapOf("wd:Q336718" to "Gallimard"))

        assertEquals(listOf("Gallimard"), properties.entities(EditionProperty.Publisher).map { it.label })
        // Not named by the server: the uri stands in.
        assertEquals(listOf("wd:Q150"), properties.entities(EditionProperty.Language).map { it.label })
        assertEquals(ClaimLiteral.Integer(256), properties.literal(EditionProperty.NumberOfPages))
        assertEquals(text("2023-03"), properties.literal(EditionProperty.PublicationDateProperty))
        assertEquals(listOf(text("123735831")), properties.claims["wdt:P268"])
        // The ISBN is not the catalogue's.
        assertNull(properties.claims["wdt:P212"])
        assertEquals(listOf("wd:Q336718", "wd:Q150"), properties.entityUris)
    }

    // What a change comes to

    @Test
    fun aSingleValueReplacedNamesTheOneItReplaces() {
        val original: EditionProperties = EditionProperties().setLiteral(ClaimLiteral.Integer(192), EditionProperty.NumberOfPages)
        val changed: EditionProperties = original.setLiteral(ClaimLiteral.Integer(256), EditionProperty.NumberOfPages)

        assertEquals(
            listOf(EditionClaimUpdate(editionUri, "wdt:P1104", ClaimLiteral.Integer(192), ClaimLiteral.Integer(256))),
            changed.updates(original, editionUri),
        )
        assertEquals(
            listOf(EditionClaimUpdate(editionUri, "wdt:P1104", ClaimLiteral.Integer(192), null)),
            changed.setLiteral(null, EditionProperty.NumberOfPages).updates(original, editionUri),
        )
    }

    @Test
    fun severalValuesSendOneUpdatePerValueAddedOrTakenAway() {
        val original: EditionProperties = EditionProperties()
            .add(gallimard, EditionProperty.Publisher)
            .addLiteral(text("123735831"), bnf)
        val changed: EditionProperties = original
            .remove(setOf(0), EditionProperty.Publisher)
            .add(EditionEntityValue(uri = "wd:Q3053361", label = "Folio"), EditionProperty.Collection)

        assertEquals(
            listOf(
                EditionClaimUpdate(editionUri, "wdt:P123", text("wd:Q336718"), null),
                EditionClaimUpdate(editionUri, "wdt:P195", null, text("wd:Q3053361")),
            ),
            changed.updates(original, editionUri),
        )
    }

    @Test
    fun theSameEntityOrLiteralIsNotAddedTwice() {
        val properties: EditionProperties = EditionProperties()
            .add(gallimard, EditionProperty.Publisher)
            .add(EditionEntityValue(uri = "wd:Q336718", label = "Éditions Gallimard"), EditionProperty.Publisher)
            .add(EditionEntityValue(label = "Le Sous-Bois"), EditionProperty.Publisher)
            .add(EditionEntityValue(label = "le sous-bois "), EditionProperty.Publisher)
            .add(EditionEntityValue(label = "  "), EditionProperty.Publisher)
            .addLiteral(text("123735831"), bnf)
            .addLiteral(text("123735831"), bnf)

        assertEquals(2, properties.entities(EditionProperty.Publisher).size)
        assertEquals(1, properties.values(bnf).size)
    }

    @Test
    fun anEntityToCreateIsSentOnlyOnceItExistsAndCollectionsAreCreatedLast() {
        val original = EditionProperties()
        var changed: EditionProperties = original
            .add(EditionEntityValue(label = "Collection du Sous-Bois"), EditionProperty.Collection)
            .add(EditionEntityValue(label = "Le Sous-Bois"), EditionProperty.Publisher)
            .add(EditionEntityValue(label = "Irina Petrova"), EditionProperty.contributors[0])

        assertTrue(changed.updates(original, editionUri).isEmpty())
        assertTrue(changed.differs(original))
        assertEquals(listOf("wdt:P123", "wdt:P655", "wdt:P195"), changed.pendingEntities.map { it.property.uri })
        assertNull(changed.publisherUri)
        assertFalse(changed.hasOrphanCollection)

        changed = changed.entityCreated(changed.pendingEntities[0].entity.id, "inv:publisher")

        assertEquals("inv:publisher", changed.publisherUri)
        assertEquals(listOf(EditionClaimUpdate(editionUri, "wdt:P123", null, text("inv:publisher"))), changed.updates(original, editionUri))
    }

    @Test
    fun aCollectionToCreateWithoutAPublisherIsAnOrphan() {
        val orphan: EditionProperties = EditionProperties().add(EditionEntityValue(label = "Nature writing"), EditionProperty.Collection)
        assertTrue(orphan.hasOrphanCollection)
        assertFalse(orphan.add(EditionEntityValue(label = "Le Sous-Bois"), EditionProperty.Publisher).hasOrphanCollection)
    }

    @Test
    fun aLandedUpdateMovesIntoTheOriginalWithTheNameTheFormHad() {
        val changed: EditionProperties = EditionProperties().add(gallimard, EditionProperty.Publisher)
        val update: EditionClaimUpdate = changed.updates(EditionProperties(), editionUri).single()

        val original: EditionProperties = EditionProperties().apply(update, changed)

        assertEquals(listOf("Gallimard"), original.entities(EditionProperty.Publisher).map { it.label })
        assertTrue(changed.updates(original, editionUri).isEmpty())
        assertFalse(changed.differs(original))
    }

    // The date

    @Test
    fun aDateIsAYearAMonthOrADayAndNothingElse() {
        assertEquals(PublicationDate.Precision.Year, PublicationDate.parse("2023")?.precision)
        assertEquals(PublicationDate.Precision.Month, PublicationDate.parse("2023-03")?.precision)
        assertEquals("2023-03-15", PublicationDate.parse("2023-03-15")?.claim)
        assertNull(PublicationDate.parse("2023-13"))
        assertNull(PublicationDate.parse("mars 2023"))
        assertNull(PublicationDate.parse("2023-03-15-01"))
        assertNull(PublicationDate.parse("-0500"))
        assertNull(PublicationDate.parse(""))

        val day = PublicationDate(year = 2023, month = 3, day = 15, precision = PublicationDate.Precision.Day)
        assertEquals("2023-03", day.copy(precision = PublicationDate.Precision.Month).claim)
        assertEquals("2023", day.copy(precision = PublicationDate.Precision.Year).claim)
        assertEquals("0950", PublicationDate(year = 950, precision = PublicationDate.Precision.Year).claim)
    }

    @Test
    fun aDateIsPrintedAtItsOwnPrecisionAndSetFromThePicker() {
        val french = java.util.Locale.FRENCH
        assertEquals("2023", PublicationDate.parse("2023")!!.displayed(french))
        assertEquals("mars 2023", PublicationDate.parse("2023-03")!!.displayed(french))
        assertEquals("15 mars 2023", PublicationDate.parse("2023-03-15")!!.displayed(french))

        val picked: PublicationDate = PublicationDate.parse("2023-03")!!.with(java.time.LocalDate.of(1971, 6, 2))
        assertEquals("1971-06", picked.claim)
    }

    // On the wire

    @Test
    fun aCountGoesOutAsAJsonNumberAUriAsAStringAndAMissingSideIsLeftOut() {
        val pages = EditionClaimUpdate(editionUri, "wdt:P1104", oldValue = null, newValue = ClaimLiteral.Integer(256))
        val json: String = ApiService.DefaultJson.encodeToString(EditionClaimUpdate.serializer(), pages)
        assertTrue(json, json.contains(""""new-value":256"""))
        assertFalse(json.contains("old-value"))
        assertEquals(pages, ApiService.DefaultJson.decodeFromString(EditionClaimUpdate.serializer(), json))

        val removal: EditionClaimUpdate = EditionClaimUpdate.of("inv:1", EditableClaimProperty.Subtitle, "Tome I", null)
        assertEquals(
            """{"uri":"inv:1","property":"wdt:P1680","old-value":"Tome I"}""",
            ApiService.DefaultJson.encodeToString(EditionClaimUpdate.serializer(), removal),
        )
    }

    @Test
    fun aClaimValueIsKeptOnlyWhenAStringOrAWholeNumber() {
        assertEquals(text("x"), ClaimLiteral.from(JsonPrimitive("x")))
        assertEquals(ClaimLiteral.Integer(256), ClaimLiteral.from(JsonPrimitive(256)))
        assertEquals(ClaimLiteral.Integer(256), ClaimLiteral.from(JsonPrimitive(256.0)))
        assertNull(ClaimLiteral.from(JsonPrimitive(2.5)))
        assertNull(ClaimLiteral.from(JsonPrimitive(true)))
        assertEquals("256", ClaimLiteral.Integer(256).text)
        assertNull(ClaimLiteral.Integer(256).string)
    }
}
