package studio.lunabee.nouveaurecit.ui.editedition

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import studio.lunabee.nouveaurecit.data.creation.EditionFormat
import studio.lunabee.nouveaurecit.data.creation.EditionPropertyCatalogue

/** Every property of every catalogue, every choice and every format has a name to print. */
class EditionPropertyLabelsTest {
    @Test
    fun everyPropertyOfEveryCatalogueHasItsLabel() {
        val missing: List<String> = EditionPropertyCatalogue.entries
            .flatMap { it.properties }
            .filterNot(EditionPropertyLabels::hasLabel)
            .map { it.labelKey }
        assertTrue("No label for $missing", missing.isEmpty())
    }

    @Test
    fun everyChoiceHasItsName() {
        val missing: List<String> = EditionPropertyCatalogue.entries
            .flatMap { catalogue -> catalogue.properties.flatMap { it.choices } }
            .filterNot(EditionPropertyLabels::hasLabel)
            .map { it.labelKey }
        assertTrue("No name for $missing", missing.isEmpty())
    }

    @Test
    fun everyFormatHasItsOwnName() {
        assertEquals(EditionFormat.entries.size, EditionFormat.entries.map(EditionPropertyLabels::name).toSet().size)
    }
}
