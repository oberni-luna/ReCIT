package studio.lunabee.nouveaurecit.ui.editedition

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import studio.lunabee.nouveaurecit.data.creation.EditionFormat
import studio.lunabee.nouveaurecit.data.creation.EditionProperty

/** Every property of the catalogue and every format has a name to print. */
class EditionPropertyLabelsTest {
    @Test
    fun everyPropertyHasItsLabel() {
        val missing: List<String> = EditionProperty.all.filterNot(EditionPropertyLabels::hasLabel).map { it.labelKey }
        assertTrue("No label for $missing", missing.isEmpty())
    }

    @Test
    fun everyFormatHasItsOwnName() {
        assertEquals(EditionFormat.entries.size, EditionFormat.entries.map(EditionPropertyLabels::name).toSet().size)
    }
}
