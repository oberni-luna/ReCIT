package studio.lunabee.nouveaurecit.ui.lists

import androidx.annotation.PluralsRes
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.withStyle
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.db.EntityListItemEntity
import studio.lunabee.nouveaurecit.data.db.ListWithElements
import studio.lunabee.nouveaurecit.data.model.EntityListType
import studio.lunabee.nouveaurecit.data.model.Merges

/** One row of the Lists tab, as `ListRowView` reads it off an `EntityList`. */
data class ListRowModel(
    val id: String,
    val name: String,
    val explanation: String,
    val type: EntityListType,
    val count: Int,
    /** The fanned covers, first in front; a single `null` slot for an empty list. */
    val covers: List<String?>,
)

/** One element of a list's detail screen, as `ListItemCellView` reads it off a work or an author. */
data class ListElementRowModel(
    val uri: String,
    val title: String,
    val subtitle: String?,
    val image: String?,
    val comment: String,
)

/**
 * The pure half of the Lists screens: `ListCoverPreview`, the name filter and sort of
 * `EntityListView`, `EntityListType.countLabel`, and the pop-on-disappearance rule of
 * `EntityListDetail`.
 */
object ListsPresentation {
    /** How many covers a row fans out (`ListCoverPreview.limit`). */
    const val COVER_LIMIT: Int = 3

    /** The first [limit] distinct uris, in the list's own `ordinal` order. */
    fun previewUris(elements: List<EntityListItemEntity>, limit: Int = COVER_LIMIT): List<String> =
        orderedElements(elements).map { it.uri }.distinct().take(limit)

    /** A list's elements in the order its detail screen shows them. */
    fun orderedElements(elements: List<EntityListItemEntity>): List<EntityListItemEntity> = elements.sortedBy { it.ordinal }

    /**
     * Lists sorted by name, kept when their name contains [query] — case- and accent-insensitive,
     * the `localizedStandardContains` of iOS. A blank query keeps them all.
     */
    fun filter(lists: List<ListWithElements>, query: String): List<ListWithElements> {
        val folded: String = Merges.fold(query)
        return lists
            .sortedBy { Merges.fold(it.list.name) }
            .filter { folded.isEmpty() || Merges.fold(it.list.name).contains(folded) }
    }

    /**
     * The rows the tab shows. [images] maps an entity uri to its cover — works for work and
     * publisher lists, authors for author lists — and a uri it lacks shows the grey slot.
     */
    fun rows(lists: List<ListWithElements>, query: String, images: Map<String, String?>): List<ListRowModel> =
        filter(lists, query).map { entry ->
            val uris: List<String> = previewUris(entry.elements)
            ListRowModel(
                id = entry.list.id,
                name = entry.list.name,
                explanation = entry.list.explanation,
                type = entry.list.type,
                count = entry.elements.size,
                covers = if (uris.isEmpty()) listOf(null) else uris.map { images[it] },
            )
        }

    /** The uris whose covers the tab needs, split by what they are: (works, authors). Publishers have none. */
    fun coverUris(lists: List<ListWithElements>): Pair<List<String>, List<String>> {
        val works: MutableSet<String> = linkedSetOf()
        val authors: MutableSet<String> = linkedSetOf()
        lists.forEach { entry ->
            val uris: List<String> = previewUris(entry.elements)
            when (entry.list.type) {
                EntityListType.Work -> works += uris
                EntityListType.Author -> authors += uris
                EntityListType.Publisher -> Unit
            }
        }
        return works.toList() to authors.toList()
    }

    /** `EntityListType.countLabel`. */
    @PluralsRes
    fun countPlural(type: EntityListType): Int = when (type) {
        EntityListType.Work -> R.plurals.list_count_work
        EntityListType.Author -> R.plurals.list_count_author
        EntityListType.Publisher -> R.plurals.list_count_publisher
    }

    /**
     * `EntityListDetail.popIfTheListIsGone`: leave on the *transition* to missing, not on the value,
     * so a screen opened before the first sync waits instead of leaving.
     */
    fun shouldLeave(wasMissing: Boolean, isMissing: Boolean): Boolean = isMissing && !wasMissing

    /** The form refuses an empty name only when it files a work into the new list, as on iOS. */
    fun canSubmit(isFiling: Boolean, name: String): Boolean = !isFiling || name.isNotBlank()

    /** The `**bold**` markdown the iOS catalogue carries, as an [AnnotatedString]. */
    fun boldMarkdown(text: String): AnnotatedString = buildAnnotatedString {
        text.split("**").forEachIndexed { index, part ->
            if (index % 2 == 1) withStyle(SpanStyle(fontWeight = FontWeight.Bold)) { append(part) } else append(part)
        }
    }
}
