package studio.lunabee.nouveaurecit.data.creation

import org.junit.Assert.assertEquals
import org.junit.Test

/** `NewBookDraftsTests`: a closed « Nouveau livre » reopens on what was typed, and only from where it was started. */
class NewBookDraftsTest {
    private val dune: NewBookOrigin = NewBookOrigin.Search("dune")

    @Test
    fun theSameQueryReopensItsDraft() {
        val drafts = NewBookDrafts()
        val typed: NewBookDraft = drafts.draft(dune).copy(title = "Dune")
        drafts.remember(typed, dune)
        assertEquals(typed, drafts.draft(NewBookOrigin.Search("dune")))
    }

    @Test
    fun anotherQueryStartsBlank() {
        val drafts = NewBookDrafts()
        drafts.remember(drafts.draft(dune).copy(title = "Dune"), dune)
        val other: NewBookOrigin = NewBookOrigin.Search("solaris")
        assertEquals(other.blankDraft, drafts.draft(other))
    }

    @Test
    fun scanDraftsAreStillKeptByIsbn() {
        val drafts = NewBookDrafts()
        val scan: NewBookOrigin = NewBookOrigin.Scan("9782494289857")
        val typed: NewBookDraft = drafts.draft(scan).copy(title = "Le Ministère des Rêves")
        drafts.remember(typed, scan)
        assertEquals(typed, drafts.draft(NewBookOrigin.Scan("9782494289857")))
        assertEquals(NewBookDraft(isbn = "9782493373052"), drafts.draft(NewBookOrigin.Scan("9782493373052")))
    }

    @Test
    fun aPublishedDraftIsForgotten() {
        val drafts = NewBookDrafts()
        drafts.remember(drafts.draft(dune).copy(title = "Dune"), dune)
        drafts.forget(dune)
        assertEquals(dune.blankDraft, drafts.draft(dune))
    }
}
