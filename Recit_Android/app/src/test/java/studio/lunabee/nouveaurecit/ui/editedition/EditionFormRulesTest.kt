package studio.lunabee.nouveaurecit.ui.editedition

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import studio.lunabee.nouveaurecit.data.creation.ClaimLiteral
import studio.lunabee.nouveaurecit.data.creation.EditionProperties
import studio.lunabee.nouveaurecit.data.creation.EditionProperty
import studio.lunabee.nouveaurecit.data.creation.EditionWork
import studio.lunabee.nouveaurecit.data.creation.NewBookAuthor
import studio.lunabee.nouveaurecit.data.creation.PublicationDate
import studio.lunabee.nouveaurecit.data.creation.WorkEdit

/** The decisions the edition form's pages make on their own. */
class EditionFormRulesTest {
    private val bnf: EditionProperty = EditionProperty.named("wdt:P268")!!
    private val openLibrary: EditionProperty = EditionProperty.named("wdt:P648")!!

    @Test
    fun theWorksSectionSaysWhatIsMissing() {
        assertEquals(EditionFormRules.WorksFooter.Empty, EditionFormRules.worksFooter(emptyList()))
        assertEquals(EditionFormRules.WorksFooter.NewWorkNeedsAuthor, EditionFormRules.worksFooter(listOf(WorkEdit.newTitled("Lucioles"))))
        val named: WorkEdit = WorkEdit.newTitled("Lucioles").addAuthor(NewBookAuthor(name = "Ursula K. Le Guin"))
        assertEquals(EditionFormRules.WorksFooter.Default, EditionFormRules.worksFooter(listOf(named)))
    }

    @Test
    fun aWorkSaysWhereItIsChanged() {
        assertEquals(EditionFormRules.WorkFooter.Wikidata, EditionFormRules.workFooter(WorkEdit.existing(EditionWork(uri = "wd:Q1", title = "Dune"))))
        assertEquals(EditionFormRules.WorkFooter.New, EditionFormRules.workFooter(WorkEdit.newTitled("Dune")))
        assertEquals(EditionFormRules.WorkFooter.Default, EditionFormRules.workFooter(WorkEdit.existing(EditionWork(uri = "inv:1", title = "Dune"))))
    }

    @Test
    fun aLanguageIsChosenNeverCreated() {
        assertFalse(EditionFormRules.offersCreation(EditionProperty.Language, "français"))
        assertTrue(EditionFormRules.offersCreation(EditionProperty.Publisher, "Gallimard"))
        assertFalse(EditionFormRules.offersCreation(EditionProperty.Publisher, "  "))
    }

    @Test
    fun aCollectionIsCreatedOnlyUnderAPublisher() {
        assertFalse(EditionFormRules.canCreate(EditionProperty.Collection, hasPublisher = false))
        assertTrue(EditionFormRules.canCreate(EditionProperty.Collection, hasPublisher = true))
        assertTrue(EditionFormRules.canCreate(EditionProperty.Publisher, hasPublisher = false))
        assertFalse(EditionFormRules.canCreate(EditionProperty.Language, hasPublisher = true))
    }

    @Test
    fun namesAreJoinedAsASentence() {
        assertEquals("", EditionFormRules.joinedNames(emptyList(), "et"))
        assertEquals("A", EditionFormRules.joinedNames(listOf("A"), "et"))
        assertEquals("A et B", EditionFormRules.joinedNames(listOf("A", "B"), "et"))
        assertEquals("A, B et C", EditionFormRules.joinedNames(listOf("A", "B", "C"), "et"))
    }

    @Test
    fun aCountKeepsOnlyItsDigitsAndIsANumber() {
        assertEquals(ClaimLiteral.Integer(256), EditionFormRules.countLiteral(EditionProperty.NumberOfPages, "2a56"))
        assertNull(EditionFormRules.countLiteral(EditionProperty.NumberOfPages, ""))
        assertNull(EditionFormRules.countLiteral(EditionProperty.NumberOfPages, "0"))
    }

    @Test
    fun identifiersAreListedInTheCatalogueOrderAndRemovedOneByOne() {
        val properties: EditionProperties = EditionProperties()
            .addLiteral(ClaimLiteral.Text("OL61173905M"), openLibrary)
            .addLiteral(ClaimLiteral.Text("123735831"), bnf)
            .addLiteral(ClaimLiteral.Text("12373583x"), bnf)
        val entries: List<EditionFormRules.IdentifierEntry> = EditionFormRules.identifierEntries(EditionProperty.Group.Databases, properties)
        assertEquals(listOf("123735831", "12373583x", "OL61173905M"), entries.map { it.value.text })
        assertTrue(EditionFormRules.identifierEntries(EditionProperty.Group.Links, properties).isEmpty())

        val removed: EditionProperties = EditionFormRules.removing(entries[1], properties)
        assertEquals(listOf("123735831", "OL61173905M"), EditionFormRules.identifierEntries(EditionProperty.Group.Databases, removed).map { it.value.text })
    }

    @Test
    fun anIdentifierSaysItsExampleUntilItIsWrong() {
        assertEquals(EditionFormRules.IdentifierStatus.Example("123735831"), EditionFormRules.identifierStatus(bnf, ""))
        assertEquals(EditionFormRules.IdentifierStatus.Example("123735831"), EditionFormRules.identifierStatus(bnf, "cb123735831"))
        assertEquals(EditionFormRules.IdentifierStatus.Invalid, EditionFormRules.identifierStatus(bnf, "12"))
        val website: EditionProperty = EditionProperty.named("wdt:P856")!!
        assertEquals(EditionFormRules.IdentifierStatus.Example("https://"), EditionFormRules.identifierStatus(website, "https://inventaire.io"))
    }

    @Test
    fun theDatePageOpensOnTheEditionsDateOrThisYear() {
        val dated: EditionProperties = EditionProperties().setLiteral(ClaimLiteral.Text("2023-03"), EditionProperty.PublicationDateProperty)
        assertEquals(PublicationDate(2023, 3, 1, PublicationDate.Precision.Month), EditionFormRules.initialDate(dated, thisYear = 2026))
        assertEquals(PublicationDate(2026, precision = PublicationDate.Precision.Year), EditionFormRules.initialDate(EditionProperties(), thisYear = 2026))
    }

    @Test
    fun aTypedYearKeepsFourDigitsAndNeverZero() {
        assertEquals(1984, EditionFormRules.typedYear("1984"))
        assertEquals(1984, EditionFormRules.typedYear("19845"))
        assertEquals(19, EditionFormRules.typedYear("1a9"))
        assertNull(EditionFormRules.typedYear(""))
        assertNull(EditionFormRules.typedYear("0"))
    }

    @Test
    fun theContributionsLinkEscapesTheName() {
        assertEquals(
            "https://inventaire.io/users/Olive%20B/contributions",
            BibliographicDataLinks.contributions("Olive B", "https://inventaire.io"),
        )
    }
}
