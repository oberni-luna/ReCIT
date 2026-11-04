package studio.lunabee.nouveaurecit.ui.lists

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import studio.lunabee.nouveaurecit.data.db.EntityListEntity
import studio.lunabee.nouveaurecit.data.db.ListWithElements
import studio.lunabee.nouveaurecit.data.db.UserEntity
import studio.lunabee.nouveaurecit.data.model.UserRelation

/** `NetworkListsTests`: « Mes listes » by name, then « Dans mon réseau », the most recently changed first. */
class ListsTabSectionsTest {
    private val lea: UserEntity = UserEntity(id = "lea", username = "Léa", relation = UserRelation.Friend)
    private val ines: UserEntity = UserEntity(id = "ines", username = "Inès", relation = UserRelation.Friend)

    private fun list(id: String, name: String, creator: String?, created: Double = 0.0, updated: Double? = null): ListWithElements =
        ListWithElements(EntityListEntity(id = id, name = name, creatorId = creator, created = created, updated = updated), emptyList())

    private val stored: List<ListWithElements> = listOf(
        list("m2", "Zola", "me"),
        list("m1", "À lire", null),
        list("l1", "Polars", "lea", created = 100.0, updated = 300.0),
        list("i1", "Poésie", "ines", created = 200.0),
        list("l2", "Romans", "lea", created = 400.0),
        list("s1", "Polars aussi", "stranger", created = 900.0),
    )

    @Test
    fun mine_by_name_then_my_friends_most_recently_changed_first() {
        val sections: ListsTabSections = ListsTabSections.of(stored, "me", listOf(lea, ines))
        assertEquals(listOf("m1", "m2"), sections.mine.map { it.list.id })
        assertEquals(listOf("l2", "l1", "i1"), sections.network.map { it.list.list.id })
        assertEquals(listOf("lea", "lea", "ines"), sections.network.map { it.owner.id })
    }

    @Test
    fun a_stranger_whose_profile_was_opened_stays_out_of_the_tab() {
        val sections: ListsTabSections = ListsTabSections.of(stored, "me", listOf(lea, ines))
        assertTrue(sections.network.none { it.list.list.id == "s1" })
        assertTrue(sections.mine.none { it.list.id == "s1" })
    }

    @Test
    fun without_friends_the_tab_holds_mine_alone() {
        val sections: ListsTabSections = ListsTabSections.of(stored, "me", emptyList())
        assertEquals(listOf("m1", "m2"), sections.mine.map { it.list.id })
        assertTrue(sections.network.isEmpty())
    }

    @Test
    fun the_search_filters_both_sections_and_empties_one_with_no_match() {
        val sections: ListsTabSections = ListsTabSections.of(stored, "me", listOf(lea, ines)).matching("po")
        assertTrue(sections.mine.isEmpty())
        assertEquals(listOf("l1", "i1"), sections.network.map { it.list.list.id })
        assertEquals(listOf("m2"), ListsTabSections.of(stored, "me", listOf(lea, ines)).matching("ZOLA").mine.map { it.list.id })
    }

    @Test
    fun nothing_stored_is_empty() {
        assertTrue(ListsTabSections.of(emptyList(), "me", listOf(lea)).isEmpty)
    }
}
