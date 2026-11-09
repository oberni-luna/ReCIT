package studio.lunabee.nouveaurecit.data.creation

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/** `NewBookOriginTests`: what « Nouveau livre » opens on, from the scanner and from Recherche. */
class NewBookOriginTest {
    @Test
    fun aTextQueryOpensTheWorkSearchOnItAndLeavesTheIsbnToType() {
        val origin = NewBookOrigin.Search(" étincelles écosocialistes ")
        assertEquals("étincelles écosocialistes", origin.workQuery)
        assertTrue(origin.isIsbnEditable)
        assertNull(origin.isbn)
        assertEquals("", origin.blankDraft.isbn)
    }

    @Test
    fun anIsbnQueryOpensAnEmptyWorkSearchWithTheThirteenDigits() {
        val origin = NewBookOrigin.Search("978-2-07-036002-4")
        assertEquals("", origin.workQuery)
        assertTrue(origin.isIsbnEditable)
        assertEquals("9782070360024", origin.isbn)
        assertEquals("9782070360024", origin.blankDraft.isbn)
    }

    @Test
    fun anIsbn10QueryStartsAsThirteenDigits() {
        assertEquals("9782070360024", NewBookOrigin.Search("2-07-036002-4").blankDraft.isbn)
    }

    @Test
    fun aScanKeepsItsBarcodeReadOnlyAndAnEmptyWorkSearch() {
        val origin = NewBookOrigin.Scan("9782494289857")
        assertEquals("", origin.workQuery)
        assertFalse(origin.isIsbnEditable)
        assertEquals("9782494289857", origin.isbn)
        assertEquals("9782494289857", origin.blankDraft.isbn)
    }
}
