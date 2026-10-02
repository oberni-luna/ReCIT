package studio.lunabee.nouveaurecit.ui.lists

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.db.EntityListEntity
import studio.lunabee.nouveaurecit.data.db.EntityListItemEntity
import studio.lunabee.nouveaurecit.data.db.ListWithElements
import studio.lunabee.nouveaurecit.data.model.EntityListType

class ListsPresentationTest {
    private fun element(uri: String, ordinal: String, listId: String = "l"): EntityListItemEntity =
        EntityListItemEntity(id = "$listId-$uri-$ordinal", listId = listId, uri = uri, ordinal = ordinal)

    private fun list(id: String, name: String, type: EntityListType = EntityListType.Work, elements: List<EntityListItemEntity> = emptyList()) =
        ListWithElements(EntityListEntity(id = id, name = name, type = type), elements)

    @Test
    fun the_preview_takes_the_first_three_distinct_uris_in_ordinal_order() {
        val elements: List<EntityListItemEntity> = listOf(
            element("wd:C", "2"),
            element("wd:A", "0"),
            element("wd:A", "1"),
            element("wd:D", "3"),
            element("wd:B", "1"),
        )
        assertEquals(listOf("wd:A", "wd:B", "wd:C"), ListsPresentation.previewUris(elements))
    }

    @Test
    fun the_filter_folds_case_and_accents_and_sorts_by_name() {
        val lists: List<ListWithElements> = listOf(list("1", "À offrir"), list("2", "Envies"), list("3", "à lire"))
        assertEquals(listOf("3", "1", "2"), ListsPresentation.filter(lists, "").map { it.list.id })
        assertEquals(listOf("3", "1"), ListsPresentation.filter(lists, "A").map { it.list.id })
        assertEquals(listOf("2"), ListsPresentation.filter(lists, "ENVIÉ").map { it.list.id })
    }

    @Test
    fun an_empty_list_fans_one_grey_slot_and_a_known_cover_shows() {
        val rows: List<ListRowModel> = ListsPresentation.rows(
            lists = listOf(list("1", "Vide"), list("2", "Pleine", elements = listOf(element("wd:A", "0"), element("wd:B", "1")))),
            query = "",
            images = mapOf("wd:A" to "https://a"),
        )
        assertEquals(listOf<String?>(null), rows.first { it.id == "1" }.covers)
        assertEquals(listOf("https://a", null), rows.first { it.id == "2" }.covers)
        assertEquals(2, rows.first { it.id == "2" }.count)
    }

    @Test
    fun cover_uris_split_works_from_authors_and_skip_publishers() {
        val (works, authors) = ListsPresentation.coverUris(
            listOf(
                list("1", "W", EntityListType.Work, listOf(element("wd:W", "0"))),
                list("2", "A", EntityListType.Author, listOf(element("wd:P", "0"))),
                list("3", "P", EntityListType.Publisher, listOf(element("wd:X", "0"))),
            ),
        )
        assertEquals(listOf("wd:W"), works)
        assertEquals(listOf("wd:P"), authors)
    }

    @Test
    fun each_type_counts_with_its_own_plural() {
        assertEquals(R.plurals.list_count_work, ListsPresentation.countPlural(EntityListType.Work))
        assertEquals(R.plurals.list_count_author, ListsPresentation.countPlural(EntityListType.Author))
        assertEquals(R.plurals.list_count_publisher, ListsPresentation.countPlural(EntityListType.Publisher))
    }

    @Test
    fun the_detail_leaves_only_when_the_list_goes_missing() {
        assertTrue(ListsPresentation.shouldLeave(wasMissing = false, isMissing = true))
        assertFalse(ListsPresentation.shouldLeave(wasMissing = true, isMissing = true))
        assertFalse(ListsPresentation.shouldLeave(wasMissing = true, isMissing = false))
        assertFalse(ListsPresentation.shouldLeave(wasMissing = false, isMissing = false))
    }

    @Test
    fun only_filing_refuses_an_empty_name() {
        assertFalse(ListsPresentation.canSubmit(isFiling = true, name = "  "))
        assertTrue(ListsPresentation.canSubmit(isFiling = true, name = "À lire"))
        assertTrue(ListsPresentation.canSubmit(isFiling = false, name = ""))
    }

    @Test
    fun bold_markdown_drops_the_markers_and_bolds_the_span() {
        val text = ListsPresentation.boldMarkdown("**Une étagère** range les livres.")
        assertEquals("Une étagère range les livres.", text.text)
        assertEquals(1, text.spanStyles.size)
        assertEquals(0, text.spanStyles.single().start)
        assertEquals("Une étagère".length, text.spanStyles.single().end)
    }
}
