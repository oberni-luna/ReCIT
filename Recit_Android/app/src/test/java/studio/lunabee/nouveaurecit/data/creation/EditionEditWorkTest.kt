package studio.lunabee.nouveaurecit.data.creation

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Test
import java.util.UUID

/**
 * `EditionEditWorkTests`: the works of « Modifier l'édition » — listed, added from the search or created,
 * detached with a swipe, renamed and given or relieved of authors in « Modifier l'œuvre ». What has to
 * exist before a claim can name it is created first, once: a retry never creates an author or a work twice.
 */
class EditionEditWorkTest {
    private val editionUri: String = "inv:eba78fdf11371f4920d21cd07baa40cb"
    private val workUri: String = "inv:eba78fdf11371f4920d21cd07baa3239"
    private val penss = EditionWork(uri = workUri, title = "Penss et les plis du monde", titleLanguage = "fr")
    private val candidate = WorkCandidate(uri = "wd:Q1", title = "Penss", authors = listOf("Jérémie Moreau"), year = "2019")
    private val moreau = NewBookAuthor(name = "Jérémie Moreau", uri = "wd:Q3177937")

    private fun edit(works: List<EditionWork> = emptyList()): EditionEdit = EditionEdit(
        EditionClaims(
            uri = editionUri,
            title = "Penss et les plis du monde",
            isbn = "978-2-413-01351-8",
            workUris = works.map { it.uri },
            labelLanguage = "fr",
        ),
        works,
    )

    private fun EditionEdit.firstWork(transform: (WorkEdit) -> WorkEdit): EditionEdit = updatingWork(works[0].id, transform)

    @Test
    fun aWorkAddedFromTheSearchIsClaimedOnTheEditionAndListedOnce() {
        var edit: EditionEdit = edit(listOf(penss)).addWork(candidate).addWork(candidate)

        assertEquals(listOf(workUri, "wd:Q1"), edit.works.map { it.uri })
        assertTrue(edit.isSaveable)
        assertEquals(EditionEditStep.Claim(EditionClaimUpdate.of(editionUri, EditableClaimProperty.Work, null, "wd:Q1")), edit.nextStep)

        edit = edit.landed(edit.claimUpdates[0])

        assertEquals(listOf(workUri, "wd:Q1"), edit.original.workUris)
        assertFalse(edit.hasChanges)
    }

    @Test
    fun aWorkDetachedIsUnclaimedWithNoneLeftTheEditionCannotBeSaved() {
        var edit: EditionEdit = edit(listOf(penss)).addWork(candidate).let { it.landed(it.claimUpdates[0]) }

        edit = edit.detachWork(edit.works[0].id)
        assertEquals(listOf(EditionClaimUpdate.of(editionUri, EditableClaimProperty.Work, workUri, null)), edit.claimUpdates)
        assertTrue(edit.isSaveable)

        edit = edit.detachWork(edit.works[0].id)
        assertTrue(edit.hasChanges)
        assertFalse(edit.isSaveable)
    }

    @Test
    fun aWorkCreatedNeedsATitleAndAnAuthorBeforeItCanBeSaved() {
        var edit: EditionEdit = edit(listOf(penss)).startNewWork("  penss et les plis du monde ")
        val created: WorkEdit = edit.works.last()

        assertEquals("Penss et les plis du monde", created.title)
        assertTrue(created.isNew)
        assertFalse(edit.isSaveable)

        edit = edit.updatingWork(created.id) { it.addAuthor(moreau) }
        assertTrue(edit.isSaveable)

        edit = edit.updatingWork(created.id) { it.copy(title = " ") }
        assertFalse(edit.isSaveable)
    }

    @Test
    fun aWorkCreatedGoesItsNewAuthorsThenTheWorkThenTheEditionsClaimOnIt() {
        var edit: EditionEdit = edit().startNewWork("Penss")
        val id: UUID = edit.works[0].id
        edit = edit.firstWork { it.addAuthor(NewBookAuthor(name = "Jérémie Moreau")).addAuthor(NewBookAuthor(name = "Someone Known", uri = "wd:Q1")) }

        val step: EditionEditStep.CreateAuthor = edit.nextStep as? EditionEditStep.CreateAuthor ?: return fail("expected the new author first")
        assertEquals("Jérémie Moreau", step.label)
        assertEquals("fr", step.language)

        edit = edit.authorCreated(step.id, "inv:author")
        assertEquals(EditionEditStep.CreateWork(id, "Penss", "fr", listOf("inv:author", "wd:Q1")), edit.nextStep)

        edit = edit.workCreated(id, "inv:work")
        assertEquals(EditionEditStep.Claim(EditionClaimUpdate.of(editionUri, EditableClaimProperty.Work, null, "inv:work")), edit.nextStep)

        edit = edit.landed(edit.claimUpdates[0])
        assertNull(edit.nextStep)
        assertEquals(listOf("Jérémie Moreau", "Someone Known"), edit.works[0].original?.authors?.map { it.trimmedName })
        assertFalse(edit.hasChanges)
    }

    @Test
    fun authorsAddedToAndTakenFromAWorkAreClaimedOnTheWork() {
        var edit: EditionEdit = edit(listOf(penss.copy(authors = listOf(moreau))))
            .firstWork { it.addAuthor(NewBookAuthor(name = "Lucie Durand", uri = "inv:lucie")).removeAuthors(setOf(0)) }

        assertTrue(edit.isSaveable)
        assertEquals(
            listOf(
                EditionClaimUpdate.of(workUri, EditableClaimProperty.Author, null, "inv:lucie"),
                EditionClaimUpdate.of(workUri, EditableClaimProperty.Author, "wd:Q3177937", null),
            ),
            edit.claimUpdates,
        )

        edit = edit.landed(edit.claimUpdates[0]).let { it.landed(it.claimUpdates[0]) }

        assertEquals(listOf("inv:lucie"), edit.works[0].original?.authors?.map { it.uri })
        assertFalse(edit.hasChanges)
    }

    @Test
    fun aWorkRenamedGoesOutAsALabelInTheLanguageOfItsTitleAfterTheClaims() {
        var edit: EditionEdit = edit(listOf(penss)).firstWork { it.copy(title = "Penss") }.copy(title = "Penss (poche)")

        assertEquals(
            EditionEditStep.Claim(EditionClaimUpdate.of(editionUri, EditableClaimProperty.Title, "Penss et les plis du monde", "Penss (poche)")),
            edit.nextStep,
        )
        edit = edit.landed(edit.claimUpdates[0])

        assertEquals(EditionEditStep.Label(EntityLabelUpdate(uri = workUri, lang = "fr", value = "Penss")), edit.nextStep)
        edit = edit.landed(edit.labelUpdates[0])

        assertNull(edit.nextStep)
        assertFalse(edit.hasChanges)
    }

    @Test
    fun anAuthorAlreadyOnTheWorkIsNotAddedAgain() {
        val edit: EditionEdit = edit(listOf(penss.copy(authors = listOf(moreau))))
            .firstWork { it.addAuthor(moreau.copy(id = UUID.randomUUID())).addAuthor(NewBookAuthor(name = "jérémie moreau")) }
        assertEquals(1, edit.works[0].authors.size)
        assertFalse(edit.hasChanges)
    }

    @Test
    fun aWikidataWorkIsShownAndNotChanged() {
        val edit: EditionEdit = edit(listOf(EditionWork(uri = "wd:Q1", title = "Le Comte de Monte-Cristo")))
            .firstWork { it.addAuthor(NewBookAuthor(name = "Alexandre Dumas")).copy(title = "Le Comte") }

        assertFalse(edit.works[0].isEditable)
        assertTrue(edit.works[0].authors.isEmpty())
        assertTrue(edit.labelUpdates.isEmpty())
        // Without a title it still counts as complete: it is not this form's to name.
        assertTrue(edit.firstWork { it.copy(title = "") }.works[0].isComplete)
    }

    @Test
    fun aWorkTheDescriptionLeftOutIsStillListedAndNotDetached() {
        val edit = EditionEdit(EditionClaims(uri = editionUri, title = "Penss", workUris = listOf(workUri, "inv:other")), listOf(penss))
        assertEquals(listOf(workUri, "inv:other"), edit.works.map { it.uri })
        assertFalse(edit.hasChanges)
        assertTrue(edit.claimUpdates.isEmpty())
    }

    @Test
    fun aCreatedAuthorKeepsItsUriAndTheRetryDoesNotCreateItAgain() {
        var edit: EditionEdit = edit(listOf(penss)).firstWork { it.addAuthor(NewBookAuthor(name = "Lucie Durand")) }

        val step: EditionEditStep.CreateAuthor = edit.nextStep as? EditionEditStep.CreateAuthor ?: return fail("expected the author first")
        edit = edit.authorCreated(step.id, "inv:lucie")

        assertEquals(EditionEditStep.Claim(EditionClaimUpdate.of(workUri, EditableClaimProperty.Author, null, "inv:lucie")), edit.nextStep)
    }

    @Test
    fun theEntitiesTheEditionNamesAreCreatedAfterTheWorksPublisherFirst() {
        val opened: EditionEdit = edit(listOf(penss))
        var edit: EditionEdit = opened.copy(
            properties = opened.properties
                .add(EditionEntityValue(label = "Nature writing"), EditionProperty.Collection)
                .add(EditionEntityValue(label = "Le Sous-Bois"), EditionProperty.Publisher),
        )

        val publisher: EditionEditStep.CreateEntity = edit.nextStep as EditionEditStep.CreateEntity
        assertEquals(EntityCreationKind.Publisher, publisher.kind)
        assertEquals("Le Sous-Bois", publisher.label)
        edit = edit.entityCreated(publisher.id, "inv:publisher")

        val collection: EditionEditStep.CreateEntity = edit.nextStep as EditionEditStep.CreateEntity
        assertEquals(EntityCreationKind.Collection("inv:publisher"), collection.kind)
        edit = edit.entityCreated(collection.id, "inv:collection")

        assertEquals(listOf("wdt:P123", "wdt:P195"), edit.claimUpdates.map { it.property })
    }

    @Test
    fun aWorkRowShowsItsTitleAndItsNamedAuthors() {
        val row: WorkCandidate = WorkEdit.existing(penss.copy(authors = listOf(moreau, NewBookAuthor(name = " ")))).candidate
        assertEquals(workUri, row.uri)
        assertEquals("Jérémie Moreau", row.detail)
        assertEquals(listOf("Jérémie Moreau"), EditionWork.of(candidate).authors.map { it.name })
    }
}
