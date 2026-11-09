package studio.lunabee.nouveaurecit.data.lists

import studio.lunabee.nouveaurecit.data.db.EntityListItemEntity
import studio.lunabee.nouveaurecit.data.db.ListWithElements
import studio.lunabee.nouveaurecit.data.db.UserEntity
import studio.lunabee.nouveaurecit.data.model.EntityListType

/**
 * `Model/Lists/BookListEntry.swift`: one row of the book screen's « Dans les listes » — a list holding the
 * book's work, the friend who made it when it is a friend's ([owner], `null` for mine), and the work the
 * list opens on ([focusUri]).
 */
data class BookListEntry(val list: ListWithElements, val owner: UserEntity?, val focusUri: String) {
    companion object {
        /**
         * The lists of works holding one of [workUris], mine and my [friends]', the most recently changed
         * first. A list holding two works of a recueil comes once, opened on the first in the list's order
         * (the lowest `ordinal`). A stranger's list, stored since their profile was opened, is left out.
         */
        fun entries(
            lists: List<ListWithElements>,
            workUris: Collection<String>,
            myUserId: String?,
            friends: List<UserEntity>,
        ): List<BookListEntry> {
            val friendsById: Map<String, UserEntity> = friends.associateBy { it.id }
            return lists
                .filter { it.list.type == EntityListType.Work }
                .mapNotNull { entry ->
                    val focus: EntityListItemEntity = entry.elements
                        .filter { it.uri in workUris }
                        .minByOrNull { it.ordinal }
                        ?: return@mapNotNull null
                    if (entry.list.isCreatedByMe(myUserId)) return@mapNotNull BookListEntry(entry, null, focus.uri)
                    entry.list.friendCreator(myUserId, friendsById)?.let { BookListEntry(entry, it, focus.uri) }
                }
                .sortedWith(compareByDescending<BookListEntry> { it.list.list.lastChanged }.thenBy { it.list.list.id })
        }
    }
}
