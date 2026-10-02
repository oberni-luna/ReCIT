package studio.lunabee.nouveaurecit.network

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import studio.lunabee.nouveaurecit.network.dto.EntityResultsDto
import studio.lunabee.nouveaurecit.network.dto.ItemsDto

class ImageUrlTest {
    @Test
    fun the_three_shapes() {
        assertEquals("https://x/y.jpg", ImageUrl.absolute("https://x/y.jpg"))
        assertEquals("https://inventaire.io/img/entities/1", ImageUrl.absolute("/img/entities/1"))
        assertEquals("https://commons.wikimedia.org/wiki/Special:FilePath/A b.jpg?width=512", ImageUrl.absolute("A b.jpg"))
        assertNull(ImageUrl.absolute(""))
        assertNull(ImageUrl.absolute(null))
    }
}

class DtoDecodingTest {
    private val json = ApiService.DefaultJson

    @Test
    fun entities_tolerate_missing_labels_and_mixed_claims() {
        val body = """
            {"entities":{"wd:Q1":{"uri":"wd:Q1","claims":{"wdt:P50":["wd:Q2"],"wdt:P1104":[312],"wdt:P31":[true]}}}}
        """.trimIndent()
        val entity = json.decodeFromString(EntityResultsDto.serializer(), body).entities.getValue("wd:Q1")
        assertEquals(listOf("wd:Q2"), entity.claimStrings("wdt:P50"))
        assertEquals(312.0, entity.claimNumber("wdt:P1104")!!, 0.0)
        assertEquals(emptyMap<String, String>(), entity.labels)
    }

    @Test
    fun items_read_their_colon_named_snapshot() {
        val body = """
            {"items":[{"_id":"i","_rev":"1","entity":"isbn:9","transaction":"giving","owner":"u","created":1.7e12,
             "snapshot":{"entity:title":"Dune","entity:authors":"Frank Herbert","entity:image":"/img/entities/x"}}],
             "total":1,"offset":0}
        """.trimIndent()
        val item = json.decodeFromString(ItemsDto.serializer(), body).items.single()
        assertEquals("Dune", item.snapshot.title)
        assertEquals("Frank Herbert", item.snapshot.authors)
    }
}
