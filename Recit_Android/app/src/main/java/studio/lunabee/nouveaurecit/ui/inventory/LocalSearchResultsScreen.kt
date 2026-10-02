package studio.lunabee.nouveaurecit.ui.inventory

import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Scaffold
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import studio.lunabee.nouveaurecit.AppContainer
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.db.ItemRow
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.ui.common.InventoryItemRow
import studio.lunabee.nouveaurecit.ui.common.RecitTopBar
import studio.lunabee.nouveaurecit.ui.common.recitViewModel
import studio.lunabee.nouveaurecit.ui.navigation.BookAnchor
import studio.lunabee.nouveaurecit.ui.navigation.Destination
import studio.lunabee.nouveaurecit.ui.navigation.Navigator

/**
 * `InventorySearchAllLocalView` — « Tout voir »: every local match for the query, mine first then
 * newest, ranked by the same function as the capped section so the two never disagree.
 */
@Composable
fun LocalSearchResultsScreen(destination: Destination.LocalSearchResults, navigator: Navigator) {
    val viewModel: LocalSearchResultsViewModel = recitViewModel(key = "localSearch:${destination.query}") {
        LocalSearchResultsViewModel(it, destination.query)
    }
    val state: LocalSearchResultsViewModel.State by viewModel.state.collectAsStateWithLifecycle()

    Scaffold(
        topBar = { RecitTopBar(title = stringResource(R.string.inventory_search_local_section), onBack = navigator::pop) },
        containerColor = RecitTheme.colors.backgroundSecondary,
    ) { padding ->
        LazyColumn(Modifier.fillMaxSize().padding(padding)) {
            items(state.items, key = { it.item.id }) { row ->
                InventoryItemRow(
                    row = row,
                    showsOwner = row.item.ownerId != state.myUserId,
                    onClick = { navigator.push(Destination.Book(BookAnchor.Item(row.item.id))) },
                )
                HorizontalDivider(Modifier.padding(start = Spacing.medium), color = RecitTheme.colors.borderDefault)
            }
        }
    }
}

class LocalSearchResultsViewModel(container: AppContainer, query: String) : ViewModel() {
    data class State(val items: List<ItemRow>, val myUserId: String?)

    val state: StateFlow<State> = combine(container.inventory.observeAll(), container.users.myUserId) { items, myId ->
        val ranked: List<ItemRow> = myId?.let {
            InventorySearchRanking.rankItems(items, query, it, limit = InventorySearchRanking.NO_LIMIT).items
        }.orEmpty()
        State(ranked, myId)
    }.stateIn(viewModelScope, SharingStarted.Eagerly, State(emptyList(), null))
}
