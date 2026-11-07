package studio.lunabee.exlibris.backend.groups

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class GroupSlugTest {
    @Test
    fun `a slug keeps letters and dashes, as inventaire's slugify`() {
        assertEquals("club-de-lecture", GroupSlug.of("Club de lecture"))
        assertEquals("les-amis-du-livre", GroupSlug.of("  Les  Amis.du.livre "))
        assertEquals("latelier", GroupSlug.of("L'Atelier"))
        assertEquals("lecteurices-de-lyon", GroupSlug.of("Lecteur·ices de Lyon"))
        assertEquals("", GroupSlug.of("2024"))
    }

    @Test
    fun `candidates count up after the slug`() {
        assertEquals(listOf("club", "club.1", "club.2"), GroupSlug.candidates("Club").take(3).toList())
    }

    @Test
    fun `a name is 1 to 80 characters, leaves a slug, and never looks like an id`() {
        assertTrue(GroupSlug.isValidName("Club"))
        assertFalse(GroupSlug.isValidName(""))
        assertFalse(GroupSlug.isValidName("2024"))
        assertFalse(GroupSlug.isValidName("a".repeat(81)))
        assertFalse(GroupSlug.isValidName("0123456789abcdef0123456789abcdef"))
    }
}
