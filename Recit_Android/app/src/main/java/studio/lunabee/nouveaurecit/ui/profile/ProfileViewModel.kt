package studio.lunabee.nouveaurecit.ui.profile

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import studio.lunabee.nouveaurecit.AppContainer
import studio.lunabee.nouveaurecit.data.db.UserEntity

/** `ProfileView`'s state: my user, the count under my name, the notice, and signing out. */
@OptIn(ExperimentalCoroutinesApi::class)
class ProfileViewModel(private val container: AppContainer) : ViewModel() {
    val user: StateFlow<UserEntity?> = container.users.myUser
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(STOP_TIMEOUT), null)

    /** `UserHeaderView` + `OwnedItemCountText`: counted locally once my inventory has synced. */
    val itemCount: StateFlow<Int> = container.users.myUser
        .flatMapLatest { user: UserEntity? ->
            if (user == null) flowOf(0) else container.inventory.observeCountOf(user.id).map { displayedItemCount(user, it) }
        }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(STOP_TIMEOUT), 0)

    /** `null` until DataStore answers, so a dismissed notice does not flash in at launch. */
    val isNoticeDismissed: StateFlow<Boolean?> = container.preferences.observeBoolean(NOTICE_DISMISSED_KEY)
        .map<Boolean, Boolean?> { it }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(STOP_TIMEOUT), null)

    private val _isSigningOut: MutableStateFlow<Boolean> = MutableStateFlow(false)
    val isSigningOut: StateFlow<Boolean> = _isSigningOut.asStateFlow()

    /** Kept on the device, not on the account: signing out and in again does not bring it back. */
    fun dismissNotice() {
        viewModelScope.launch { container.preferences.setBoolean(NOTICE_DISMISSED_KEY, true) }
    }

    /**
     * Drops the session. Run on the application scope: the root swaps this whole tab view for the
     * welcome screen the moment the session goes, which clears this view model mid-call.
     */
    fun signOut() {
        if (_isSigningOut.value) return
        _isSigningOut.value = true
        container.applicationScope.launch {
            try {
                container.session.signOut()
            } finally {
                _isSigningOut.value = false
            }
        }
    }

    companion object {
        const val NOTICE_DISMISSED_KEY: String = "profile.inventaireNotice.dismissed"
        private const val STOP_TIMEOUT: Long = 5_000

        /**
         * Whose count the local store can answer for: mine, once my inventory has synced. Before
         * that, the server's snapshot is the only figure that is not a lie.
         */
        fun displayedItemCount(user: UserEntity, localCount: Int): Int =
            if (user.lastInventorySync != null) localCount else user.itemCount
    }
}
