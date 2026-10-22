package studio.lunabee.nouveaurecit.ui.auth.coverwall

import org.junit.Assert.assertEquals
import org.junit.Test

class CoverWallCatalogTest {
    @Test
    fun missing_empty_and_repeated_covers_are_dropped_in_order() {
        assertEquals(
            listOf("/img/entities/a", "/img/entities/b"),
            CoverWallCatalog.coverPaths(listOf(null, "/img/entities/a", "", "/img/entities/b", "/img/entities/a")),
        )
    }

    @Test
    fun the_catalog_stops_at_its_limit() {
        assertEquals(3, CoverWallCatalog.coverPaths((1..10).map { "/img/entities/$it" }, limit = 3).size)
    }

    @Test
    fun an_entity_path_is_asked_at_the_drawn_size() {
        assertEquals("/img/entities/180x270/abc", CoverWallCatalog.sizedPath("/img/entities/abc", 180f, 270.2f))
        assertEquals("https://inventaire.io/img/entities/180x270/abc", CoverWallCatalog.url("https://inventaire.io", "/img/entities/abc", 180f, 270f))
    }

    @Test
    fun other_shapes_are_left_alone() {
        assertEquals("/img/entities/90x90/abc", CoverWallCatalog.sizedPath("/img/entities/90x90/abc", 180f, 270f))
        assertEquals("https://commons.wikimedia.org/x.jpg", CoverWallCatalog.url("https://inventaire.io", "https://commons.wikimedia.org/x.jpg", 180f, 270f))
        assertEquals("abc", CoverWallCatalog.sizedPath("abc", 180f, 270f))
        assertEquals("/img/entities/abc", CoverWallCatalog.sizedPath("/img/entities/abc", 0f, 270f))
    }
}
