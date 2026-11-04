package studio.lunabee.nouveaurecit.ui.editedition

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import studio.lunabee.nouveaurecit.data.creation.EditionEntityValue
import studio.lunabee.nouveaurecit.data.creation.EditionProperties
import studio.lunabee.nouveaurecit.data.creation.EditionProperty
import studio.lunabee.nouveaurecit.data.creation.EditionPropertyCatalogue
import studio.lunabee.nouveaurecit.data.creation.HumanProperties
import studio.lunabee.nouveaurecit.data.creation.WorkProperties
import java.util.UUID

/** Which page a property pushes, and how the stack of pages over the form moves. */
class EditEditionPageTest {
    @Test
    fun theDateOpensItsOwnPage() {
        assertEquals(
            EditionPropertyStep.Date(EditionProperty.PublicationDateProperty.uri),
            EditionPropertyStep.opening(EditionProperty.PublicationDateProperty, EditionProperties()),
        )
        assertEquals(
            EditionPropertyStep.Date(HumanProperties.BirthDate.uri),
            EditionPropertyStep.opening(HumanProperties.BirthDate, EditionProperties(catalogue = EditionPropertyCatalogue.Human)),
        )
    }

    @Test
    fun aChoiceTooLongForAMenuOpensItsList() {
        assertEquals(
            EditionPropertyStep.Choice(WorkProperties.Form.uri),
            EditionPropertyStep.opening(WorkProperties.Form, EditionProperties(catalogue = EditionPropertyCatalogue.Work)),
        )
    }

    @Test
    fun anEntityPageClosesWithEverythingItPushed() {
        val entity: EditEditionPage = EditEditionPage.Entity("inv:work")
        val stack: PageStack<EditEditionPage> = PageStack<EditEditionPage>()
            .push(entity)
            .push(EditEditionPage.Entity("inv:person"))
            .push(EditEditionPage.EntityProperty("inv:person", EditionPropertyStep.IdentifierCatalog(EditionProperty.Group.Databases)))

        assertTrue(stack.popTo(entity).isEmpty)
        assertEquals(listOf(entity), stack.popTo(EditEditionPage.Entity("inv:person")).pages)
        assertEquals(stack, stack.popTo(EditEditionPage.Entity("inv:other")))
    }

    @Test
    fun anEntityPropertyWithNoValueGoesStraightToTheSearch() {
        assertEquals(
            EditionPropertyStep.Picker(EditionProperty.Publisher.uri),
            EditionPropertyStep.opening(EditionProperty.Publisher, EditionProperties()),
        )
    }

    @Test
    fun anEntityPropertyThatNamesSomeoneListsItsValuesFirst() {
        val properties: EditionProperties = EditionProperties().add(EditionEntityValue(uri = "wd:Q1", label = "Gallimard"), EditionProperty.Publisher)
        assertEquals(
            EditionPropertyStep.Values(EditionProperty.Publisher.uri),
            EditionPropertyStep.opening(EditionProperty.Publisher, properties),
        )
    }

    @Test
    fun anEmptyStackIsTheForm() {
        val stack: PageStack<EditEditionPage> = PageStack()
        assertTrue(stack.isEmpty)
        assertNull(stack.top)
        assertTrue(stack.pop().isEmpty)
    }

    @Test
    fun anIdentifierAddedClosesItsInputAndTheCatalogue() {
        val stack: PageStack<EditEditionPage> = PageStack<EditEditionPage>()
            .push(EditEditionPage.Property(EditionPropertyStep.IdentifierCatalog(EditionProperty.Group.Databases)))
            .push(EditEditionPage.Property(EditionPropertyStep.IdentifierInput("wdt:P268")))
        assertTrue(stack.pop(EditionPropertyStep.PAGES_CLOSED_BY_IDENTIFIER).isEmpty)
    }

    @Test
    fun poppingMoreThanThereIsStopsAtTheForm() {
        val stack: PageStack<EditEditionPage> = PageStack<EditEditionPage>().push(EditEditionPage.Help)
        assertTrue(stack.pop(5).isEmpty)
    }

    @Test
    fun aNewWorkReplacesTheSearchThatFoundNothing() {
        val id: UUID = UUID.randomUUID()
        val stack: PageStack<EditEditionPage> = PageStack<EditEditionPage>()
            .push(EditEditionPage.WorkSearch)
            .replaceTop(EditEditionPage.WorkDetail(id))
        assertEquals(listOf(EditEditionPage.WorkDetail(id)), stack.pages)
    }
}
