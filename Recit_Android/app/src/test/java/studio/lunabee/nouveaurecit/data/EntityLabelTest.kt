package studio.lunabee.nouveaurecit.data

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import studio.lunabee.nouveaurecit.data.model.EntityLabel
import studio.lunabee.nouveaurecit.data.model.Merges
import studio.lunabee.nouveaurecit.network.dto.EntityResultDto

/*
 * `EntityLabelTests`: the name a work or an author wears, and where Wikidata keeps it now.
 *
 * `an_author_named_only_under_mul_is_named_by_it` is the case this helper was written for: `wd:Q535`
 * carries « Victor Hugo » under `mul` and under neither `fr` nor `en`, and the old fallback named him
 * in whichever language the JSON listed first.
 */
class EntityLabelTest {
    @Test
    fun french_comes_first_then_english() {
        assertEquals("Les Misérables", EntityLabel.resolve(mapOf("en" to "The Wretched", "fr" to "Les Misérables", "mul" to "x")))
        assertEquals("The Wretched", EntityLabel.resolve(mapOf("en" to "The Wretched", "mul" to "x")))
    }

    @Test
    fun an_author_named_only_under_mul_is_named_by_it() {
        // The shape of `wd:Q535`, verified against production on 2026-10-24, Russian first as served.
        val labels: Map<String, String> = linkedMapOf("ru" to "Виктор Гюго", "ja" to "ヴィクトル・ユーゴー", "mul" to "Victor Hugo")
        assertEquals("Victor Hugo", EntityLabel.resolve(labels, originalLang = "fr"))
    }

    @Test
    fun without_fr_en_or_mul_the_original_language_answers() {
        assertEquals("Война и мир", EntityLabel.resolve(mapOf("de" to "Krieg und Frieden", "ru" to "Война и мир"), originalLang = "ru"))
    }

    @Test
    fun any_other_label_is_picked_the_same_way_on_every_call() {
        val labels: Map<String, String> = linkedMapOf("ru" to "Виктор Гюго", "de" to "Victor Hugo", "ja" to "ヴィクトル・ユーゴー")
        assertEquals("Victor Hugo", EntityLabel.resolve(labels))
    }

    @Test
    fun an_empty_label_is_not_a_name_and_the_next_one_is_tried() {
        assertEquals("Victor Hugo", EntityLabel.resolve(mapOf("fr" to "", "en" to "", "mul" to "Victor Hugo")))
        assertNull(EntityLabel.resolve(mapOf("fr" to "", "ru" to "")))
    }

    @Test
    fun no_label_at_all_is_no_name() {
        assertNull(EntityLabel.resolve(emptyMap()))
        assertNull(EntityLabel.resolve(null))
    }

    @Test
    fun authors_and_works_are_named_through_it() {
        val hugo = EntityResultDto(uri = "wd:Q535", labels = linkedMapOf("ru" to "Виктор Гюго", "mul" to "Victor Hugo"))
        assertEquals("Victor Hugo", Merges.author(null, hugo).name)
        assertEquals("Victor Hugo", Merges.author(Merges.author(null, hugo).copy(name = "Виктор Гюго"), hugo).name)
        val war = EntityResultDto(uri = "wd:Q161531", originalLang = "ru", labels = linkedMapOf("de" to "Krieg und Frieden", "ru" to "Война и мир"))
        assertEquals("Война и мир", Merges.work(null, war).title)
    }
}
