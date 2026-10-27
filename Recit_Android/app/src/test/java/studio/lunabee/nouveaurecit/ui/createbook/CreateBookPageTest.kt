package studio.lunabee.nouveaurecit.ui.createbook

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import studio.lunabee.nouveaurecit.data.creation.NewBookAuthor
import studio.lunabee.nouveaurecit.data.creation.NewBookDraft
import studio.lunabee.nouveaurecit.data.creation.WorkCandidate
import studio.lunabee.nouveaurecit.data.creation.WorkEdit

/** Where the scanner's « Nouveau livre » opens and goes, and what « Édition de » says about the work. */
class CreateBookPageTest {
    private val blank: NewBookDraft = NewBookDraft(isbn = "9782494289857")
    private val ministry = WorkCandidate(uri = "wd:Q123", title = "Le Ministère des Rêves", authors = listOf("Momtchil Milanov"))

    @Test
    fun aNewDraftOpensOnTheWorkSearch() {
        assertTrue(CreateBookPage.resuming(blank).isEmpty)
    }

    @Test
    fun aDraftThatNamesAWorkReopensOnTheEditionsForm() {
        assertEquals(listOf(CreateBookPage.Edition), CreateBookPage.resuming(blank.choose(ministry)).pages)
        assertEquals(listOf(CreateBookPage.Edition), CreateBookPage.resuming(blank.startNewWork("solaris")).pages)
    }

    @Test
    fun aDetachedWorkSendsTheDraftBackToTheSearch() {
        assertTrue(CreateBookPage.resuming(blank.choose(ministry).detachWork()).isEmpty)
    }

    @Test
    fun pickingAWorkLeavesTheEditionAloneAndCreatingOnePutsItsPageOverTheEdition() {
        assertEquals(listOf(CreateBookPage.Edition), CreateBookPage.afterChoosingWork.pages)
        assertEquals(listOf(CreateBookPage.Edition, CreateBookPage.NewWork), CreateBookPage.afterStartingNewWork.pages)
    }

    @Test
    fun theWorkSectionSaysWhatItHolds() {
        assertEquals(CreateBookRules.WorkFooter.Chosen, CreateBookRules.workFooter(blank.choose(ministry)))
        assertEquals(CreateBookRules.WorkFooter.NewWork, CreateBookRules.workFooter(blank.startNewWork("solaris")))
        assertEquals(CreateBookRules.WorkFooter.None, CreateBookRules.workFooter(blank))
    }

    @Test
    fun aWorkRecognisedByTheDryRunStillReadsAsTheUsersOwnInTheForm() {
        val recognised: NewBookDraft = blank.startNewWork("solaris").recognised("wd:Q1130619")
        assertEquals(CreateBookRules.WorkFooter.NewWork, CreateBookRules.workFooter(recognised))
    }

    @Test
    fun theWorkBeingDescribedIsShownWithItsNamedAuthors() {
        val draft: NewBookDraft = blank.startNewWork("solaris")
            .addAuthor(NewBookAuthor(name = " Stanisław Lem ", uri = "wd:Q40662"))
            .addAuthor(NewBookAuthor(name = " "))
        val row: WorkCandidate = CreateBookRules.newWorkCandidate(draft)
        assertEquals("Solaris", row.title)
        assertEquals(listOf("Stanisław Lem"), row.authors)
        assertEquals("", row.uri)
    }

    @Test
    fun nouvelleOeuvreEditsTheDraftsWorkAsANewOne() {
        val draft: NewBookDraft = blank.startNewWork("solaris").addAuthor(NewBookAuthor(name = "Stanisław Lem"))
        val work: WorkEdit = CreateBookRules.newWork(draft)
        assertTrue(work.isNew)
        assertTrue(work.isEditable)
        assertEquals("Solaris", work.title)
        assertEquals(draft.authors, work.authors)
        // The same identity every time: the page is redrawn from the draft at each change.
        assertEquals(work.id, CreateBookRules.newWork(draft.renameWork("Solaris !")).id)
    }
}
