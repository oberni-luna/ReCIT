package studio.lunabee.nouveaurecit.data.creation

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * `NewBookDraftTests`: what the draft of a book being created does on its own, before anything is sent —
 * which work it is attached to, what its edition is called, and when it is enough to publish.
 */
class NewBookDraftTest {
    private val ministry = WorkCandidate(uri = "wd:Q123", title = "Le Ministère des Rêves", authors = listOf("Momtchil Milanov"), year = "2019")
    private val future = WorkCandidate(uri = "wd:Q102036201", title = "Le Ministère du futur", authors = listOf("Kim Stanley Robinson"), year = "2020")

    // Picking a work

    @Test
    fun pickingAWorkAttachesTheEditionToItTitledAsTheWork() {
        val draft: NewBookDraft = NewBookDraft(isbn = "9782494289857").choose(ministry)
        assertEquals("wd:Q123", draft.workUri)
        assertEquals("Le Ministère des Rêves", draft.title)
        assertTrue(draft.hasAnsweredWorkQuestion)
    }

    @Test
    fun pickingAnotherWorkCarriesTheTitleAlongWhileTheUserHasNotChangedIt() {
        assertEquals("Le Ministère du futur", NewBookDraft(isbn = "9782494289857").choose(ministry).choose(future).title)
    }

    @Test
    fun aTitleTheUserTypedIsTheirsAndALaterPickLeavesItAlone() {
        val draft: NewBookDraft = NewBookDraft(isbn = "9782494289857")
            .choose(ministry)
            .copy(title = "Le Ministère des rêves, édition de poche")
            .choose(future)
        assertEquals("Le Ministère des rêves, édition de poche", draft.title)
    }

    @Test
    fun anEditionOfAKnownWorkIsPublishableWithItsTitleAlone() {
        assertTrue(NewBookDraft(isbn = "9782494289857").choose(ministry).isPublishable)
    }

    // Starting a work of one's own

    @Test
    fun creatingTheWorkFromASearchTakesTheSearchWithACapital() {
        val draft: NewBookDraft = NewBookDraft(isbn = "9782493373052").startNewWork(" étincelles écosocialistes ")
        assertEquals("Étincelles écosocialistes", draft.workTitle)
        assertEquals("Étincelles écosocialistes", draft.title)
        assertNull(draft.workUri)
        assertFalse(draft.hasAnsweredWorkQuestion)
    }

    @Test
    fun leavingAPickedWorkForgetsIt() {
        val draft: NewBookDraft = NewBookDraft(isbn = "9782493373052").choose(ministry).startNewWork("étincelles écosocialistes")
        assertNull(draft.chosenWork)
        assertNull(draft.workUri)
        assertEquals("Étincelles écosocialistes", draft.title)
    }

    @Test
    fun theEditionsTitleFollowsTheWorksWhileTheUserHasNotChangedIt() {
        val draft: NewBookDraft = NewBookDraft(isbn = "9782493373052").startNewWork("étincelles").renameWork("Étincelles écosocialistes")
        assertEquals("Étincelles écosocialistes", draft.title)
    }

    @Test
    fun aTitleTheUserTypedStaysWhenTheWorkIsRenamed() {
        val draft: NewBookDraft = NewBookDraft(isbn = "9782493373052")
            .startNewWork("étincelles écosocialistes")
            .copy(title = "Étincelles écosocialistes (poche)")
            .renameWork("Étincelles écosocialistes !")
        assertEquals("Étincelles écosocialistes (poche)", draft.title)
    }

    @Test
    fun aWorkBeingCreatedNeedsAnAuthorAndTheEditionsTitle() {
        var draft: NewBookDraft = NewBookDraft(isbn = "9782493373052").startNewWork("étincelles écosocialistes")
        assertFalse(draft.isPublishable)

        draft = draft.copy(authors = listOf(NewBookAuthor(name = "  ")))
        assertFalse(draft.isPublishable)

        draft = draft.copy(authors = listOf(NewBookAuthor(name = "Michael Löwy", uri = "wd:Q560474")))
        assertTrue(draft.isPublishable)

        assertFalse(draft.copy(title = "").isPublishable)
    }

    @Test
    fun withoutAWorkTitleTheWorkIsNamedAfterTheEditionAsTheScannersFormAlwaysDid() {
        val draft = NewBookDraft(isbn = "9782493373052", title = " Penss ", authors = listOf(NewBookAuthor(name = "Jérémie Moreau")))
        assertEquals("Penss", draft.workLabel)
        assertFalse(draft.hasWork)
        assertTrue(draft.isPublishable)
    }

    // The edition's properties

    @Test
    fun whatTheIsbnSaysBecomesTheEditionsLanguageUnlessOneWasChosen() {
        val french = EditionLanguage(uri = "wd:Q150", code = "fr")
        val draft: NewBookDraft = NewBookDraft(isbn = "9782494289857").withLanguage(french)
        assertEquals(listOf("wd:Q150"), draft.properties.entities(EditionProperty.Language).map { it.uri })
        assertEquals(french, draft.language)
        assertEquals("fr", draft.labelLanguage)

        val chosen: NewBookDraft = NewBookDraft(isbn = "9782494289857").let {
            it.copy(properties = it.properties.add(EditionEntityValue(uri = "wd:Q1860", label = "anglais"), EditionProperty.Language))
        }.withLanguage(french)
        assertEquals(listOf("wd:Q1860"), chosen.properties.entities(EditionProperty.Language).map { it.uri })
    }

    @Test
    fun aWorkDetachedLeavesTheDraftWithoutOneAndUnpublishable() {
        val draft: NewBookDraft = NewBookDraft(isbn = "9782494289857").choose(ministry)
        assertTrue(draft.isPublishable)

        val detached: NewBookDraft = draft.detachWork()
        assertFalse(detached.hasWork)
        assertFalse(detached.isPublishable)
    }

    @Test
    fun aCollectionToCreateNeedsAPublisherBeforeTheBookCanBePublished() {
        var draft: NewBookDraft = NewBookDraft(isbn = "9782494289857").choose(ministry)
        draft = draft.copy(properties = draft.properties.add(EditionEntityValue(label = "Nature writing"), EditionProperty.Collection))
        assertFalse(draft.isPublishable)

        draft = draft.copy(properties = draft.properties.add(EditionEntityValue(label = "Le Sous-Bois"), EditionProperty.Publisher))
        assertTrue(draft.isPublishable)
    }

    @Test
    fun anEntityCreatedIsNamedByItsUriFromThenOn() {
        val pending = EditionEntityValue(label = "Le Sous-Bois")
        val draft: NewBookDraft = NewBookDraft(isbn = "9782494289857")
            .let { it.copy(properties = it.properties.add(pending, EditionProperty.Publisher)) }
            .entityCreated(pending.id, "inv:publisher")
        assertTrue(draft.properties.pendingEntities.isEmpty())
        assertEquals("inv:publisher", draft.properties.publisherUri)
    }

    // The work's authors

    @Test
    fun anAuthorIsAddedOnceAndABlankOneNever() {
        val lem = NewBookAuthor(name = "Stanisław Lem", uri = "wd:Q40662")
        val draft: NewBookDraft = NewBookDraft(isbn = "9782494289857").startNewWork("solaris")
            .addAuthor(lem)
            .addAuthor(NewBookAuthor(name = "stanisław lem"))
            .addAuthor(NewBookAuthor(name = "  "))
        assertEquals(listOf(lem), draft.authors)
        assertTrue(draft.isPublishable)
    }

    @Test
    fun removingTheLastAuthorLeavesAWorkThatCannotBePublished() {
        val draft: NewBookDraft = NewBookDraft(isbn = "9782494289857").startNewWork("solaris")
            .addAuthor(NewBookAuthor(name = "Stanisław Lem"))
            .addAuthor(NewBookAuthor(name = "Jean-Michel Jarre"))
        assertEquals(listOf("Stanisław Lem"), draft.removeAuthor(1).authors.map { it.name })
        assertFalse(draft.removeAuthor(1).removeAuthor(0).isPublishable)
    }

    // The dry run's question

    @Test
    fun onlyAWorkBeingDescribedIsAskedAboutAndOnlyOnce() {
        val blank = NewBookDraft(isbn = "9782494289857")
        assertTrue(blank.startNewWork("solaris").asksWhichWork)
        assertFalse(blank.choose(ministry).asksWhichWork)
        assertFalse(blank.startNewWork("solaris").recognised("wd:Q1130619").copy(workUri = null).asksWhichWork)
    }

    @Test
    fun aRecognisedWorkIsTheDefaultAnswerUntilThePageIsLeft() {
        val described: NewBookDraft = NewBookDraft(isbn = "9782494289857").startNewWork("solaris")
        val recognised: NewBookDraft = described.recognised("wd:Q1130619")
        assertEquals("wd:Q1130619", recognised.workUri)
        assertEquals(described, recognised.leavingRecognised("wd:Q1130619"))
    }

    @Test
    fun leavingTheRecognisedWorkKeepsAPickedWorkAndAnotherAnswer() {
        val picked: NewBookDraft = NewBookDraft(isbn = "9782494289857").choose(ministry)
        assertEquals(picked, picked.leavingRecognised("wd:Q123"))
        val another: NewBookDraft = NewBookDraft(isbn = "9782494289857").startNewWork("solaris").recognised("wd:Q1").copy(workUri = null)
        assertEquals(another, another.leavingRecognised("wd:Q1"))
    }

    @Test
    fun onlyTheFirstLetterIsRaised() {
        assertEquals("Le Guin et moi", NewBookDraft.capitalizingFirstLetter("le Guin et moi"))
        assertEquals("", NewBookDraft.capitalizingFirstLetter(""))
    }
}
