package studio.lunabee.nouveaurecit.ui.profile

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import studio.lunabee.nouveaurecit.AppContainer
import studio.lunabee.nouveaurecit.data.db.ItemRow

/**
 * `AboutInventaireShelfBooks`' query: my three latest books, strictly by date added — not covers
 * first, as an étagère orders them. Fewer if I own fewer, a bare plank if none or nobody is signed in.
 */
@OptIn(ExperimentalCoroutinesApi::class)
class AboutInventaireViewModel(container: AppContainer) : ViewModel() {
    val latestBooks: StateFlow<List<ItemRow>> = container.users.myUserId
        .flatMapLatest { id -> id?.let { container.inventory.observeItemsOf(it).map { items -> items.take(LIMIT) } } ?: flowOf(emptyList()) }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(STOP_TIMEOUT), emptyList())

    private companion object {
        const val LIMIT: Int = 3
        const val STOP_TIMEOUT: Long = 5_000
    }
}
