package studio.lunabee.nouveaurecit.ui.network.groups

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import studio.lunabee.nouveaurecit.AppContainer
import studio.lunabee.nouveaurecit.data.db.UserEntity
import studio.lunabee.nouveaurecit.data.groups.ReaderGroup
import kotlin.coroutines.cancellation.CancellationException

/**
 * One group as the repository holds it, and the people it names as the store holds them — what a
 * group's screen and its members screen read.
 *
 * With [fetches], the group is read afresh as the screen opens (`GET /api/groups/by-id`): a group
 * seen from the search is not known yet, and one of mine may have moved since the last sync.
 */
class GroupViewModel(
    private val container: AppContainer,
    val groupId: String,
    fetches: Boolean,
) : ViewModel() {
    val group: StateFlow<ReaderGroup?> = container.groups.observeGroup(groupId)
        .stateIn(viewModelScope, SharingStarted.Eagerly, container.groups.groups.value[groupId])

    val myUserId: StateFlow<String?> = container.users.myUserId

    /** Everyone the group names, by id, once the store holds them. */
    val people: StateFlow<Map<String, UserEntity>> = group
        .map { it?.everyoneIds.orEmpty() }
        .distinctUntilChanged()
        .flatMapLatest(container.users::observeUsers)
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyMap())

    private val _loadFailed: MutableStateFlow<Boolean> = MutableStateFlow(false)
    val loadFailed: StateFlow<Boolean> = _loadFailed.asStateFlow()

    init {
        if (fetches) {
            viewModelScope.launch {
                try {
                    container.groups.fetchGroup(groupId)
                    _loadFailed.value = false
                } catch (cancellation: CancellationException) {
                    throw cancellation
                } catch (_: Exception) {
                    _loadFailed.value = true
                }
            }
        }
    }
}
