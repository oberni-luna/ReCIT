package studio.lunabee.nouveaurecit.data.lists

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import studio.lunabee.nouveaurecit.data.db.EntityListEntity
import studio.lunabee.nouveaurecit.data.db.EntityListItemEntity
import studio.lunabee.nouveaurecit.data.db.ListWithElements
import studio.lunabee.nouveaurecit.data.db.UserEntity
import studio.lunabee.nouveaurecit.data.model.EntityListType
import studio.lunabee.nouveaurecit.data.model.UserRelation

/** `BookListEntryTests`: « Dans les listes » keeps mine and my friends' lists of works, once each, the most recently changed first. */
class BookListEntryTest {
    private val lea: UserEntity = UserEntity(id = "lea", username = "Léa", relation = UserRelation.Friend)

    private fun list(
        id: String,
        creator: String?,
        holding: List<String> = listOf("wd:Q1"),
        ordinals: List<String> = holding.map { "0" },
        type: EntityListType = EntityListType.Work,
        created: Double = 0.0,
        updated: Double? = null,
    ): ListWithElements = ListWithElements(
        EntityListEntity(id = id, name = id, creatorId = creator, type = type, created = created, updated = updated),
        holding.zip(ordinals).map { (uri, ordinal) ->
            EntityListItemEntity(id = "$id-$uri", listId = id, uri = uri, ordinal = ordinal, entityType = type)
        },
    )

    @Test
    fun keeps_my_lists_and_my_friends_and_leaves_a_strangers_out() {
        val entries: List<BookListEntry> = BookListEntry.entries(
            lists = listOf(list("mine", "me"), list("unstamped", null), list("lea", "lea"), list("stranger", "stranger")),
            workUris = listOf("wd:Q1"),
            myUserId = "me",
            friends = listOf(lea),
        )

        assertEquals(setOf("mine", "unstamped", "lea"), entries.map { it.list.list.id }.toSet())
        assertNull(entries.first { it.list.list.id == "mine" }.owner)
        assertEquals("lea", entries.first { it.list.list.id == "lea" }.owner?.id)
    }

    @Test
    fun leaves_a_list_of_authors_out() {
        val entries: List<BookListEntry> = BookListEntry.entries(
            lists = listOf(list("authors", "me", type = EntityListType.Author)),
            workUris = listOf("wd:Q1"),
            myUserId = "me",
            friends = emptyList(),
        )

        assertTrue(entries.isEmpty())
    }

    @Test
    fun shows_a_list_holding_two_works_of_a_recueil_once_on_the_first_in_list_order() {
        val entries: List<BookListEntry> = BookListEntry.entries(
            lists = listOf(list("recueil", "me", holding = listOf("wd:Q2", "wd:Q3", "wd:Q1"), ordinals = listOf("3", "0", "1"))),
            workUris = listOf("wd:Q1", "wd:Q2"),
            myUserId = "me",
            friends = emptyList(),
        )

        assertEquals(listOf("recueil"), entries.map { it.list.list.id })
        assertEquals("wd:Q1", entries.single().focusUri)
    }

    @Test
    fun orders_mine_and_my_friends_together_the_most_recently_changed_first() {
        val entries: List<BookListEntry> = BookListEntry.entries(
            lists = listOf(
                list("mine-old", "me", created = 100.0),
                list("lea-new", "lea", updated = 400.0),
                list("mine-new", "me", updated = 300.0),
                list("lea-old", "lea", created = 200.0),
            ),
            workUris = listOf("wd:Q1"),
            myUserId = "me",
            friends = listOf(lea),
        )

        assertEquals(listOf("lea-new", "mine-new", "lea-old", "mine-old"), entries.map { it.list.list.id })
    }

    @Test
    fun leaves_out_a_list_holding_none_of_the_works() {
        val entries: List<BookListEntry> = BookListEntry.entries(
            lists = listOf(list("other", "me", holding = listOf("wd:Q9"))),
            workUris = listOf("wd:Q1"),
            myUserId = "me",
            friends = emptyList(),
        )

        assertTrue(entries.isEmpty())
    }
}
