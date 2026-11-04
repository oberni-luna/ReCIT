package studio.lunabee.nouveaurecit.data.creation

import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonPrimitive
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * `EditionPropertyCatalogueTests` (iOS feature 0057): the properties each entity type shows, as tables —
 * an edition's, a work's, a person's —, and a uri read in the catalogue of the form it belongs to.
 */
class EditionPropertyCatalogueTest {
    @Test
    fun eachTypeHasItsTables() {
        assertEquals(6, WorkProperties.Type.choices.size)
        assertEquals(31, WorkProperties.Form.choices.size)
        assertEquals(20, EditionPropertyCatalogue.Work.inGroup(EditionProperty.Group.Databases).size)
        assertEquals(10, EditionPropertyCatalogue.Work.inGroup(EditionProperty.Group.Links).size)
        assertEquals(29, EditionPropertyCatalogue.Human.inGroup(EditionProperty.Group.Databases).size)
        assertEquals(11, EditionPropertyCatalogue.Human.inGroup(EditionProperty.Group.Links).size)
        assertEquals(22, EditionPropertyCatalogue.Edition.inGroup(EditionProperty.Group.Databases).size)
        assertEquals(10, EditionPropertyCatalogue.Edition.inGroup(EditionProperty.Group.Links).size)
    }

    @Test
    fun aUriIsUniqueWithinItsCatalogue() {
        for (catalogue in EditionPropertyCatalogue.entries) {
            val uris: List<String> = catalogue.properties.map { it.uri }
            assertEquals("$catalogue", uris.distinct(), uris)
        }
    }

    @Test
    fun theSameUriIsADifferentPropertyInAnotherCatalogue() {
        val editionLanguage: EditionProperty? = EditionPropertyCatalogue.Edition.property("wdt:P407")
        val originalLanguage: EditionProperty? = EditionPropertyCatalogue.Work.property("wdt:P407")
        assertEquals("edition_property_language", editionLanguage?.labelKey)
        assertEquals("entity_property_original_language", originalLanguage?.labelKey)

        val workOpenLibrary: EditionProperty? = EditionPropertyCatalogue.Work.property("wdt:P648")
        val personOpenLibrary: EditionProperty? = EditionPropertyCatalogue.Human.property("wdt:P648")
        assertEquals(ClaimLiteral.Text("OL36858W"), workOpenLibrary?.literal("OL36858W"))
        assertNull(workOpenLibrary?.literal("OL61173905M"))
        assertEquals(ClaimLiteral.Text("OL396182A"), personOpenLibrary?.literal("OL396182A"))
        assertNotEquals(workOpenLibrary, personOpenLibrary)

        assertNull(EditionPropertyCatalogue.Edition.property("wdt:P50"))
        assertEquals(WorkProperties.Author, EditionPropertyCatalogue.Work.property("wdt:P50"))
    }

    @Test
    fun theCatalogueOfAnEntityIsReadFromItsType() {
        assertEquals(EditionPropertyCatalogue.Work, EditionPropertyCatalogue.of("work"))
        assertEquals(EditionPropertyCatalogue.Human, EditionPropertyCatalogue.of("human"))
        assertEquals(EditionPropertyCatalogue.Edition, EditionPropertyCatalogue.of("edition"))
        assertNull(EditionPropertyCatalogue.of("serie"))
    }

    @Test
    fun claimsAreReadInTheCatalogueTheyAreGiven() {
        val claims: Map<String, List<JsonElement>> = mapOf(
            "wdt:P407" to listOf(JsonPrimitive("wd:Q150")),
            "wdt:P742" to listOf(JsonPrimitive("L. D.")),
            "wdt:P1104" to listOf(JsonPrimitive(256)),
        )

        val work: EditionProperties = EditionProperties.fromClaims(claims, mapOf("wd:Q150" to "français"), EditionPropertyCatalogue.Work)
        val person: EditionProperties = EditionProperties.fromClaims(claims, emptyMap(), EditionPropertyCatalogue.Human)

        assertEquals(listOf("wdt:P407"), work.values.keys.toList())
        assertEquals(listOf("français"), work.entities(WorkProperties.OriginalLanguage).map { it.label })
        assertEquals(listOf("wdt:P742"), person.values.keys.toList())
        assertTrue(person.entityUris.isEmpty())
    }
}
