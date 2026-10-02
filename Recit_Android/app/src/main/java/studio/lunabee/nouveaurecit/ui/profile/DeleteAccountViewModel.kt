package studio.lunabee.nouveaurecit.ui.profile

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import studio.lunabee.nouveaurecit.AppContainer

/** `DeleteAccountView`'s state: the summary counted from Room, and the deletion itself. */
@OptIn(ExperimentalCoroutinesApi::class)
class DeleteAccountViewModel(private val container: AppContainer) : ViewModel() {
    /**
     * Books and étagères are filtered to me because the store also holds friends' — the server
     * only deletes mine. Lists are all mine: only mine are ever synced. `null` until Room answers.
     */
    val summary: StateFlow<AccountDeletionSummary?> = container.users.myUserId
        .flatMapLatest { myId: String? ->
            if (myId == null) {
                flowOf(null)
            } else {
                combine(
                    container.inventory.observeCountOf(myId),
                    container.shelves.observeCountOf(myId),
                    container.lists.observeCount(),
                ) { books: Int, shelves: Int, lists: Int -> AccountDeletionSummary(books, shelves, lists) }
            }
        }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(STOP_TIMEOUT), null)

    private val _isDeleting: MutableStateFlow<Boolean> = MutableStateFlow(false)
    val isDeleting: StateFlow<Boolean> = _isDeleting.asStateFlow()

    /**
     * Nothing local is touched before the server has said `ok` (`SessionCoordinator.deleteAccount`).
     * On the application scope, since success swaps the root to the welcome screen; a failure leaves
     * this screen up, its button live, and [onFailure] says why.
     */
    fun deleteAccount(onFailure: (Throwable) -> Unit) {
        if (_isDeleting.value) return
        _isDeleting.value = true
        container.applicationScope.launch {
            try {
                container.session.deleteAccount()
            } catch (error: Exception) {
                onFailure(error)
            } finally {
                _isDeleting.value = false
            }
        }
    }

    private companion object {
        const val STOP_TIMEOUT: Long = 5_000
    }
}
