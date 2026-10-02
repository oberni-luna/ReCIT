package studio.lunabee.nouveaurecit.ui.inventory

import studio.lunabee.nouveaurecit.data.SearchResult

/** `Model/SearchResult/RemoteSearchState.swift`: where the call to inventaire.io stands. */
sealed interface RemoteSearchState {
    data object Idle : RemoteSearchState

    data object Loading : RemoteSearchState

    data class Loaded(val all: List<SearchResult>) : RemoteSearchState

    data object Failed : RemoteSearchState

    /** What the screen says in place of results — never more than one at a time. */
    enum class Sign { Loading, NoResult, Failure }

    val sign: Sign?
        get() = when (this) {
            Idle -> null
            Loading -> Sign.Loading
            is Loaded -> if (all.isEmpty()) Sign.NoResult else null
            Failed -> Sign.Failure
        }

    /** Empty in every state but a non-empty answer, so a stale list never sits under a new sign. */
    val results: List<SearchResult> get() = (this as? Loaded)?.all.orEmpty()
}
