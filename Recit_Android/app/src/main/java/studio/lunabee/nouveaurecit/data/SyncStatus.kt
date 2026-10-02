package studio.lunabee.nouveaurecit.data

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update

/**
 * `SyncStatusStore` and `InventorySyncProgress` together: which domain has had its first sync since
 * launch, and how far each user's first inventory sync has got (feature 0027).
 */
class SyncStatus {
    enum class Domain { Shelves, Inventory, Community, Lists }

    enum class State { Idle, Running, Completed, Failed }

    /** Items received over items announced, for a user whose inventory has never been synced. */
    data class Progress(val received: Int = 0, val announced: Int? = null) {
        val fraction: Float? get() = announced?.takeIf { it > 0 }?.let { (received.toFloat() / it).coerceIn(0f, 1f) }
    }

    private val _domains: MutableStateFlow<Map<Domain, State>> = MutableStateFlow(emptyMap())
    val domains: StateFlow<Map<Domain, State>> = _domains.asStateFlow()

    private val _firstSyncProgress: MutableStateFlow<Map<String, Progress>> = MutableStateFlow(emptyMap())
    val firstSyncProgress: StateFlow<Map<String, Progress>> = _firstSyncProgress.asStateFlow()

    fun mark(domain: Domain, state: State) {
        _domains.update { it + (domain to state) }
    }

    fun startFirstSync(userId: String) {
        _firstSyncProgress.update { it + (userId to Progress()) }
    }

    fun announce(userId: String, announced: Int) {
        _firstSyncProgress.update { map -> map[userId]?.let { map + (userId to it.copy(announced = announced)) } ?: map }
    }

    fun receive(userId: String, count: Int) {
        _firstSyncProgress.update { map -> map[userId]?.let { map + (userId to it.copy(received = it.received + count)) } ?: map }
    }

    fun endFirstSync(userId: String) {
        _firstSyncProgress.update { it - userId }
    }

    fun reset() {
        _domains.value = emptyMap()
        _firstSyncProgress.value = emptyMap()
    }
}
