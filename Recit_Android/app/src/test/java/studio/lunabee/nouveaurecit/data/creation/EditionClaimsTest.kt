package studio.lunabee.nouveaurecit.data.creation

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import studio.lunabee.nouveaurecit.data.db.EditionEntity
import studio.lunabee.nouveaurecit.network.ApiService
import studio.lunabee.nouveaurecit.network.dto.EditableEditionsDto

/**
 * `EditionClaimsTests`: reading an edition to change it — the canonical `inv:` uri behind an `isbn:` one,
 * the claims the form edits, the hash an upload answers — and what a save writes back into the store.
 */
class EditionClaimsTest {
    /** `by-uris?uris=isbn:9782370493002&attributes=info|claims`, as inventaire.io answered on 2026-10-25, trimmed. */
    private val answer: String = """
        {
          "entities": {
            "inv:69c1353d3d6a4fb21005c0d7367e1eb4": {
              "uri": "inv:69c1353d3d6a4fb21005c0d7367e1eb4",
              "type": "edition",
              "claims": {
                "wdt:P1476": ["Lucioles"],
                "wdt:P1680": ["15 fictions pour des futurs écologiques"],
                "wdt:P212": ["978-2-37049-300-2"],
                "wdt:P957": ["2-37049-300-3"],
                "invp:P2": ["75407f010cff3581bd373cc8ada59ad9259bf17a"],
                "wdt:P1104": [256]
              }
            }
          },
          "redirects": { "isbn:9782370493002": "inv:69c1353d3d6a4fb21005c0d7367e1eb4" }
        }
    """.trimIndent()

    private fun decode(json: String): List<EditionClaims> =
        ApiService.DefaultJson.decodeFromString(EditableEditionsDto.serializer(), json).entities.values.mapNotNull { EditionClaims.from(it) }

    @Test
    fun anIsbnEditionIsReadUnderTheInvUriItRedirectsTo() {
        val claims: EditionClaims = decode(answer).single()
        val expected = EditionClaims(
            uri = "inv:69c1353d3d6a4fb21005c0d7367e1eb4",
            title = "Lucioles",
            subtitle = "15 fictions pour des futurs écologiques",
            coverHash = "75407f010cff3581bd373cc8ada59ad9259bf17a",
            isbn = "978-2-37049-300-2",
            isbn10 = "2-37049-300-3",
            properties = EditionProperties().setLiteral(ClaimLiteral.Integer(256), EditionProperty.NumberOfPages),
        )
        assertEquals(expected, claims)
        assertEquals("9782370493002", claims.normalizedIsbn)
        assertEquals("https://inventaire.io/img/entities/75407f010cff3581bd373cc8ada59ad9259bf17a", claims.coverUrl)
    }

    @Test
    fun theWorkAndTheLabelLanguageAreReadWithTheEdition() {
        val claims: EditionClaims = decode(
            """{"entities":{"inv:1":{"uri":"inv:1","originalLang":"fr","claims":{"wdt:P1476":["Penss"],"wdt:P629":["inv:work"]}}}}""",
        ).single()
        assertEquals(listOf("inv:work"), claims.workUris)
        assertEquals("fr", claims.labelLanguage)
    }

    @Test
    fun withoutAnIsbn13TheIsbn10IsShownWithoutATitleAnEmptyOne() {
        val claims: EditionClaims = decode("""{"entities":{"inv:1":{"uri":"inv:1","claims":{"wdt:P957":["2-37049-300-3"]}}}}""").single()
        assertEquals("2-37049-300-3", claims.isbn)
        // Shown once, as the ISBN, not a second time under it.
        assertNull(claims.isbn10)
        assertEquals("", claims.title)
        assertNull(claims.subtitle)
        assertNull(claims.coverHash)
        assertNull(claims.coverUrl)
    }

    @Test
    fun aWikidataEditionIsNothingTheFormCanSend() {
        assertTrue(decode("""{"entities":{"wd:Q1":{"uri":"wd:Q1","claims":{"wdt:P1476":["Le Comte"]}}}}""").isEmpty())
        assertTrue(decode("""{"entities":{"inv:1":{"uri":"inv:1","type":"work"}}}""").isEmpty())
        assertFalse(EditionClaims.canEdit("wd:Q1"))
        assertTrue(EditionClaims.canEdit("isbn:9782370493002"))
        assertTrue(EditionClaims.canEdit("inv:69c1353d3d6a4fb21005c0d7367e1eb4"))
    }

    @Test
    fun anUploadsPathEndsWithTheHashInvpP2Takes() {
        val hash = "75407f010cff3581bd373cc8ada59ad9259bf17a"
        assertEquals(hash, EntityImageHash.from("/img/entities/$hash"))
        assertEquals(hash, EntityImageHash.from("https://inventaire.io/img/entities/$hash"))
        assertNull(EntityImageHash.from("/img/entities/abc123"))
        assertNull(EntityImageHash.from("/img/entities/${hash.uppercase()}"))
        assertNull(EntityImageHash.from(null))
        assertEquals("/img/entities/$hash", EntityImageHash.path(hash))
    }

    // The local edition

    @Test
    fun onlyWhatMovedIsWrittenIntoTheLocalEdition() {
        val newHash = "0123456789abcdef0123456789abcdef01234567"
        val local = EditionEntity(uri = "isbn:9782370493002", title = "Lucioles", image = "https://test.local/img/entities/from-elsewhere")
        val before = EditionClaims(uri = "inv:1", title = "Lucioles")
        val after: EditionClaims = before.copy(title = "Lucioles II", subtitle = "Tome I")

        assertNull(EditionStoreUpdate.edition(local, before, before))

        val renamed: EditionEntity = EditionStoreUpdate.edition(local, after, before)!!
        assertEquals("Lucioles II", renamed.title)
        assertEquals("Tome I", renamed.subtitle)
        // No hash before or after: the picture shown came from elsewhere, and stays.
        assertEquals("https://test.local/img/entities/from-elsewhere", renamed.image)

        val covered: EditionEntity = EditionStoreUpdate.edition(renamed, after.copy(coverHash = newHash), after)!!
        assertEquals("https://inventaire.io/img/entities/$newHash", covered.image)

        val paged: EditionEntity = EditionStoreUpdate.edition(
            renamed,
            after.copy(properties = EditionProperties().setLiteral(ClaimLiteral.Integer(256), EditionProperty.NumberOfPages)),
            after,
        )!!
        assertEquals(256, paged.numberOfPages)

        // A title emptied on the server is not written over the one shown.
        assertNull(EditionStoreUpdate.edition(renamed, after.copy(title = ""), after.copy(title = "x")))
    }
}
