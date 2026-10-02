package studio.lunabee.nouveaurecit.ui.inventory

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import studio.lunabee.nouveaurecit.AppContainer
import studio.lunabee.nouveaurecit.data.db.ItemRow
import studio.lunabee.nouveaurecit.data.db.ShelfWithItems

/** `ShelfDetailView`'s state: one shelf, its copies newest first, and whether it is mine. */
class ShelfViewModel(private val container: AppContainer, private val shelfId: String) : ViewModel() {
    data class State(val shelf: ShelfWithItems?, val books: List<ItemRow>, val isMine: Boolean, val isLoaded: Boolean)

    val state: StateFlow<State> = combine(container.shelves.observeShelf(shelfId), container.users.myUserId) { shelf, myId ->
        State(
            shelf = shelf,
            books = shelf?.items.orEmpty().sortedByDescending { it.item.created },
            isMine = shelf != null && shelf.shelf.ownerId == myId,
            isLoaded = true,
        )
    }.stateIn(viewModelScope, SharingStarted.Eagerly, State(null, emptyList(), isMine = false, isLoaded = false))

    /** Optimistic: the row leaves at once, and comes back with a snackbar if the server refuses. */
    fun remove(itemId: String) {
        viewModelScope.launch { container.shelves.removeItem(shelfId, itemId) }
    }
}
