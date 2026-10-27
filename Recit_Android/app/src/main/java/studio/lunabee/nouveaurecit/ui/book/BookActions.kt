package studio.lunabee.nouveaurecit.ui.book

import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.launch
import studio.lunabee.nouveaurecit.AppContainer
import studio.lunabee.nouveaurecit.data.db.EditionWithWorks
import studio.lunabee.nouveaurecit.data.db.ItemRow
import studio.lunabee.nouveaurecit.data.db.ShelfWithItems
import studio.lunabee.nouveaurecit.data.db.UserEntity
import studio.lunabee.nouveaurecit.data.model.EntityListType
import studio.lunabee.nouveaurecit.data.model.TransactionType
import studio.lunabee.nouveaurecit.data.model.Visibility

/** `MembershipMenuEntry`: one étagère or list of the « … » menu, and whether the book is in it. */
data class MembershipEntry(val id: String, val name: String, val isMember: Boolean)

/** The copies of an edition, split on the ownership line: mine, and other people's. */
data class EditionOwnership(val mine: ItemRow?, val others: List<ItemRow>)

/** What the book's menu needs to know about one edition, read from Room. */
data class BookActionsState(
    val editionUri: String,
    val myItemId: String?,
    val myShelves: List<MembershipEntry>,
    val myLists: List<MembershipEntry>,
    val singleWorkUri: String?,
) {
    val lines: List<BookMenuLine>
        get() = BookMenuLine.of(ownsCopy = myItemId != null, shelves = myShelves, lists = myLists, singleWorkUri = singleWorkUri)
}

/** One line of the book's menu, before it is worded — what `BookActions.menuContent` decides on iOS. */
sealed interface BookMenuLine {
    /** Étagères hold a specific copy, so filing is offered only on mine. */
    data class Shelves(val entries: List<MembershipEntry>) : BookMenuLine

    data class Lists(val entries: List<MembershipEntry>) : BookMenuLine

    data object Remove : BookMenuLine

    data object AddToInventory : BookMenuLine

    companion object {
        /**
         * Two menus, one per side of the ownership line. Listes hold works: an edition behind
         * several works ([singleWorkUri] `null`) offers no list line at all, creation included.
         */
        fun of(
            ownsCopy: Boolean,
            shelves: List<MembershipEntry>,
            lists: List<MembershipEntry>,
            singleWorkUri: String?,
        ): List<BookMenuLine> {
            val listLine: BookMenuLine? = singleWorkUri?.let { Lists(lists) }
            return if (ownsCopy) {
                listOfNotNull(Shelves(shelves), listLine, Remove)
            } else {
                listOfNotNull(listLine, AddToInventory)
            }
        }
    }
}

/**
 * `BookActionsModifier`'s reads and writes, keyed by an edition uri: my copy, my étagères and my
 * work lists with the book's membership, and the four things the menu does. The book screen and
 * the long press of a row both hold one.
 *
 * Every flow is cold: a row's holder opens nothing in Room until its menu is collected. Writes that
 * must outlive the menu run on [AppContainer.applicationScope].
 */
class BookActions(
    private val container: AppContainer,
    editionUri: Flow<String?>,
) {
    val editionWithWorks: Flow<EditionWithWorks?> = editionUri.flatMapLatest { uri ->
        uri?.let(container.entities.entities::observeEditionWithWorks) ?: flowOf(null)
    }

    private val items: Flow<List<ItemRow>> = editionUri.flatMapLatest { uri ->
        uri?.let(container.inventory::observeItemsOfEdition) ?: flowOf(emptyList())
    }

    private val myUserId: Flow<String?> = container.users.myUserId

    val ownership: Flow<EditionOwnership> = combine(items, myUserId) { rows, me ->
        val mine: ItemRow? = rows.firstOrNull { me != null && it.item.ownerId == me }
        EditionOwnership(mine, rows.filter { it.item.ownerId != me && it.owner != null })
    }

    val myShelves: Flow<List<MembershipEntry>> = combine(myUserId, ownership.map { it.mine?.item?.id }.distinctUntilChanged()) { me, itemId ->
        me to itemId
    }.flatMapLatest { (me, itemId) ->
        if (me == null || itemId == null) {
            flowOf(emptyList())
        } else {
            combine(container.shelves.observeShelvesOf(me), container.shelves.observeShelfIdsOf(itemId)) { all: List<ShelfWithItems>, memberIds: List<String> ->
                all.map { MembershipEntry(it.shelf.id, it.shelf.name, it.shelf.id in memberIds) }
            }
        }
    }

    private val singleWorkUri: Flow<String?> = editionWithWorks.map { it?.works?.singleOrNull()?.uri }.distinctUntilChanged()

    val myLists: Flow<List<MembershipEntry>> = combine(container.lists.observeLists(), singleWorkUri) { all, workUri ->
        if (workUri == null) {
            emptyList()
        } else {
            all.filter { it.list.type == EntityListType.Work }
                .sortedBy { it.list.name.lowercase() }
                .map { list -> MembershipEntry(list.list.id, list.list.name, list.elements.any { it.uri == workUri }) }
        }
    }

    /** Everything the menu reads; `null` until the edition is in the store. */
    val state: Flow<BookActionsState?> = combine(editionWithWorks, ownership, myShelves, myLists) { edition, owned, shelves, lists ->
        edition?.let {
            BookActionsState(
                editionUri = it.edition.uri,
                myItemId = owned.mine?.item?.id,
                myShelves = shelves,
                myLists = lists,
                singleWorkUri = it.works.singleOrNull()?.uri,
            )
        }
    }

    /** Optimistic, in the application scope. */
    fun toggleShelf(itemId: String, entry: MembershipEntry) {
        container.applicationScope.launch {
            if (entry.isMember) container.shelves.removeItem(entry.id, itemId) else container.shelves.addItem(entry.id, itemId)
        }
    }

    /** Adding is optimistic; removing is server-first, so it answers whether it worked. */
    suspend fun toggleList(workUri: String, entry: MembershipEntry): Boolean = if (entry.isMember) {
        report { container.lists.removeEntities(entry.id, listOf(workUri)) }
    } else {
        container.lists.addEntities(entry.id, listOf(workUri))
        true
    }

    /** Server-first: `true` once the server said `ok` and the row is gone. */
    suspend fun removeItem(itemId: String): Boolean = report { container.inventory.removeItem(itemId) }

    /** `POST /api/items`, server-first. [AddOutcome.NoUser] is said by the caller; a failure is reported. */
    suspend fun addToInventory(editionUri: String): AddOutcome {
        val me: UserEntity = container.users.myUser() ?: return AddOutcome.NoUser
        val ok: Boolean = report { container.inventory.postNewItem(editionUri, me, TransactionType.Inventorying, listOf(Visibility.Friends)) }
        return if (ok) AddOutcome.Added else AddOutcome.Failed
    }

    enum class AddOutcome { Added, NoUser, Failed }

    private suspend fun report(block: suspend () -> Unit): Boolean = try {
        block()
        true
    } catch (cancellation: CancellationException) {
        throw cancellation
    } catch (error: Exception) {
        container.errorReporter.report(error)
        false
    }
}
