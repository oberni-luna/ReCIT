package studio.lunabee.nouveaurecit.data.creation

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * `EntityEditTests` (iOS feature 0057): a work or a person as « Modifier l'œuvre » and « Modifier
 * l'auteur·ice » change it. One claim update per change, whatever the kind of value — a choice replaced,
 * a text or an entity added or taken away, a rank sent as a string —, the labels after the claims, and
 * nothing sent twice once it landed.
 */
class EntityEditTest {
    private val workUri: String = "inv:work"
    private val personUri: String = "inv:person"

    private fun work(properties: EditionProperties = EditionProperties(catalogue = EditionPropertyCatalogue.Work)): EntityEdit =
        EntityEdit.open(uri = workUri, labels = mapOf("en" to "Fireflies", "fr" to "Lucioles"), properties = properties)

    private fun person(properties: EditionProperties = EditionProperties(catalogue = EditionPropertyCatalogue.Human)): EntityEdit =
        EntityEdit.open(uri = personUri, labels = mapOf("fr" to "Lucie Durand"), properties = properties)

    private fun EntityEdit.changing(transform: (EditionProperties) -> EditionProperties): EntityEdit = copy(properties = transform(properties))

    private fun text(value: String): ClaimLiteral = ClaimLiteral.Text(value)

    // Labels

    @Test
    fun theLabelShownComesFirstAndALanguageIsAddedOnce() {
        val edit: EntityEdit = work()

        assertEquals(listOf("fr", "en"), edit.labels.map { it.language })
        assertEquals("fr", edit.labelLanguage)
        assertFalse("fr" in edit.addableLanguages)
        assertTrue("de" in edit.addableLanguages)
        assertEquals(edit.addingLabel("de"), edit.addingLabel("de").addingLabel("de"))
        // An empty label added changes nothing.
        assertFalse(edit.addingLabel("de").hasChanges)
    }

    @Test
    fun aLabelChangedOrAddedGoesOutInItsLanguageAfterTheClaims() {
        val edit: EntityEdit = work()
            .withLabel("fr", " Lucioles, quinze fictions ")
            .addingLabel("de")
            .withLabel("de", "Glühwürmchen")
            .changing { it.setLiteral(text("wd:Q1004"), WorkProperties.Type) }

        assertEquals(
            listOf(EntityLabelUpdate(workUri, "fr", "Lucioles, quinze fictions"), EntityLabelUpdate(workUri, "de", "Glühwürmchen")),
            edit.labelUpdates,
        )
        assertTrue(edit.nextStep is EditionEditStep.Claim)
        val claimed: EntityEdit = edit.landed(edit.claimUpdates.single())
        assertEquals(EditionEditStep.Label(EntityLabelUpdate(workUri, "fr", "Lucioles, quinze fictions")), claimed.nextStep)
    }

    @Test
    fun aLabelItHadEmptiedCannotBeSavedNorANameless() {
        val emptied: EntityEdit = work().withLabel("en", " ")
        assertTrue(emptied.labelUpdates.isEmpty())
        assertFalse(emptied.isSaveable)

        val nameless: EntityEdit = EntityEdit.open(workUri, emptyMap(), EditionProperties(catalogue = EditionPropertyCatalogue.Work))
            .changing { it.setLiteral(text("wd:Q8261"), WorkProperties.Form) }
        assertTrue(nameless.hasChanges)
        assertFalse(nameless.isSaveable)
        assertTrue(nameless.addingLabel("fr").withLabel("fr", "Lucioles").isSaveable)
    }

    // One claim update per change, per kind of value

    @Test
    fun aChoiceIsReplacedInOneUpdateNamingTheValueItReplaces() {
        val opened: EntityEdit = work(EditionProperties(catalogue = EditionPropertyCatalogue.Work).setLiteral(text("wd:Q7725634"), WorkProperties.Type))

        val edit: EntityEdit = opened.changing { it.setLiteral(text("wd:Q1004"), WorkProperties.Type) }

        assertEquals(listOf(EditionClaimUpdate(workUri, "wdt:P31", text("wd:Q7725634"), text("wd:Q1004"))), edit.claimUpdates)
        assertTrue(edit.isSaveable)
        // A value the server does not allow is no value.
        assertNull(WorkProperties.Type.literal("wd:Q42"))
        assertEquals(text("wd:Q8261"), WorkProperties.Form.literal("wd:Q8261"))
    }

    @Test
    fun aTextIsAddedOrTakenAwayOneUpdateEach() {
        val opened: EntityEdit = person(EditionProperties(catalogue = EditionPropertyCatalogue.Human).addLiteral(text("L. D."), HumanProperties.Pseudonym))

        val edit: EntityEdit = opened.changing { it.remove(setOf(0), HumanProperties.Pseudonym).addLiteral(text("Lulu"), HumanProperties.Pseudonym) }

        assertEquals(
            listOf(
                EditionClaimUpdate(personUri, "wdt:P742", text("L. D."), null),
                EditionClaimUpdate(personUri, "wdt:P742", null, text("Lulu")),
            ),
            edit.claimUpdates,
        )
        assertNull(HumanProperties.Pseudonym.literal("x".repeat(401)))
    }

    @Test
    fun aRankIsAPositiveWholeNumberSentAsAString() {
        assertEquals(text("3"), WorkProperties.SeriesOrdinal.literal(" 03 "))
        assertNull(WorkProperties.SeriesOrdinal.literal("0"))
        assertNull(WorkProperties.SeriesOrdinal.literal("2b"))
        assertNull(WorkProperties.SeriesOrdinal.literal("٣"))

        val edit: EntityEdit = work().changing { it.setLiteral(WorkProperties.SeriesOrdinal.literal("3"), WorkProperties.SeriesOrdinal) }

        assertEquals(listOf(EditionClaimUpdate(workUri, "wdt:P1545", null, text("3"))), edit.claimUpdates)
    }

    @Test
    fun anEntityOfAnyTypeIsClaimedByUriAndNeverCreated() {
        val subject = EditionEntityValue(uri = "wd:Q1", label = "Mer", detail = "genre")

        val edit: EntityEdit = work().changing { it.add(subject, WorkProperties.MainSubject) }

        assertEquals(listOf(EditionClaimUpdate(workUri, "wdt:P921", null, text("wd:Q1"))), edit.claimUpdates)
        assertEquals(
            listOf(EntitySearchType.Genres, EntitySearchType.Movements, EntitySearchType.Humans, EntitySearchType.Works),
            WorkProperties.MainSubject.searchTypes,
        )
        assertFalse(WorkProperties.MainSubject.allowsCreation)
        assertFalse(WorkProperties.DifferentFrom.allowsCreation)
        assertFalse(HumanProperties.DifferentFrom.allowsCreation)
        assertTrue(HumanProperties.InfluencedBy.allowsCreation)
    }

    @Test
    fun aDateAndAnIdentifierAreClaimedAsTheServerWritesThem() {
        val edit: EntityEdit = person()
            .changing { it.setLiteral(HumanProperties.BirthDate.literal("1971-06"), HumanProperties.BirthDate) }
            .changing { properties -> HumanProperties.databases.first().literal("0000 0001 2297 4701")?.let { properties.addLiteral(it, HumanProperties.databases.first()) } ?: properties }

        assertEquals(
            listOf(
                EditionClaimUpdate(personUri, "wdt:P569", null, text("1971-06")),
                EditionClaimUpdate(personUri, "wdt:P213", null, text("0000000122974701")),
            ),
            edit.claimUpdates,
        )
    }

    // Saving

    @Test
    fun aPersonToCreateGoesFirstAndIsClaimedOnceCreated() {
        var edit: EntityEdit = work().changing { it.add(EditionEntityValue(label = "Paul Martin"), WorkProperties.comicRoles[0]) }

        val step: EditionEditStep.CreateEntity = edit.nextStep as? EditionEditStep.CreateEntity ?: throw AssertionError("expected the person first")
        assertEquals(EntityCreationKind.Human, step.kind)
        assertEquals("Paul Martin", step.label)
        assertEquals("fr", step.language)
        assertTrue(edit.claimUpdates.isEmpty())

        edit = edit.entityCreated(step.id, "inv:paul")

        assertEquals(EditionEditStep.Claim(EditionClaimUpdate(workUri, "wdt:P10837", null, text("inv:paul"))), edit.nextStep)
    }

    @Test
    fun whatLandedIsNotSentAgain() {
        var edit: EntityEdit = work()
            .changing { it.setLiteral(text("wd:Q8261"), WorkProperties.Form).add(EditionEntityValue(uri = "inv:lucie", label = "Lucie"), WorkProperties.Author) }
            .withLabel("en", "Fireflies II")

        edit = edit.landed(edit.claimUpdates[0])

        assertEquals(listOf("wdt:P50"), edit.claimUpdates.map { it.property })
        edit = edit.landed(edit.claimUpdates[0]).landed(edit.labelUpdates[0])

        assertNull(edit.nextStep)
        assertFalse(edit.hasChanges)
        assertEquals(listOf("Lucie" to "inv:lucie"), edit.editionWork.authors.map { it.name to it.uri })
        assertEquals("Lucioles", edit.editionWork.title)
    }

    @Test
    fun aPersonRenamedIsShownUnderTheNewNameWithoutAChange() {
        val opened: EntityEdit = work(
            EditionProperties(catalogue = EditionPropertyCatalogue.Work).add(EditionEntityValue(uri = "inv:lucie", label = "Lucie"), WorkProperties.Author),
        )

        val edit: EntityEdit = opened.rename("inv:lucie", "Lucie Durand")

        assertEquals("Lucie Durand", edit.properties.entities(WorkProperties.Author).single().label)
        assertFalse(edit.hasChanges)
    }

    @Test
    fun onlyInventaireEntitiesAreEditable() {
        assertTrue(EntityEdit.canEdit("inv:work"))
        assertFalse(EntityEdit.canEdit("wd:Q1"))
        assertFalse(EntityEdit.canEdit("isbn:9782370493002"))
        assertFalse(EntityEdit.canEdit(null))
        assertFalse(EntityEdit.open("wd:Q1", mapOf("fr" to "Dune"), EditionProperties(catalogue = EditionPropertyCatalogue.Work)).withLabel("fr", "Dune II").isSaveable)
    }
}
