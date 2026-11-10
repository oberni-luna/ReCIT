package studio.lunabee.nouveaurecit.ui.inventory

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import studio.lunabee.nouveaurecit.AppContainer
import studio.lunabee.nouveaurecit.data.db.ItemRow

/** `ShelfAddBooksSheet`'s store: my books, which of them stand on [shelfId], and the one write. */
@OptIn(ExperimentalCoroutinesApi::class)
class ShelfAddBooksViewModel(private val container: AppContainer, private val shelfId: String) : ViewModel() {
    data class Books(val mine: List<ItemRow>, val onShelf: Set<String>)

    /** Null until both have been read once, so no empty sentence flashes before the books. */
    val books: StateFlow<Books?> = combine(
        container.users.myUserId.flatMapLatest { id -> id?.let(container.inventory::observeItemsOf) ?: flowOf(null) },
        container.shelves.observeShelf(shelfId),
    ) { items, shelf ->
        items?.let { Books(it, shelf?.items.orEmpty().map { row -> row.item.id }.toSet()) }
    }.stateIn(viewModelScope, SharingStarted.Eagerly, null)

    /** Optimistic, in the application scope: the sheet closes as the books reach the étagère. */
    fun add(itemIds: List<String>) {
        container.applicationScope.launch { container.shelves.addItems(shelfId, itemIds) }
    }
}
