package studio.lunabee.nouveaurecit.ui.search

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
 * `FriendsLatestBooksView` — « Tout voir » from « Chez mes amis »: every book my friends have, most
 * recently added first — the carousel without its cap, each row naming its owner.
 */
@Composable
fun FriendsLatestBooksScreen(navigator: Navigator) {
    val viewModel: FriendsLatestBooksViewModel = recitViewModel { FriendsLatestBooksViewModel(it) }
    val items: List<ItemRow> by viewModel.items.collectAsStateWithLifecycle()

    Scaffold(
        topBar = { RecitTopBar(title = stringResource(R.string.inventory_search_friends_section), onBack = navigator::pop) },
        containerColor = RecitTheme.colors.backgroundSecondary,
    ) { padding ->
        LazyColumn(Modifier.fillMaxSize().padding(padding)) {
            items(items, key = { it.item.id }) { row ->
                InventoryItemRow(
                    row = row,
                    showsOwner = true,
                    onClick = { navigator.push(Destination.Book(BookAnchor.Item(row.item.id))) },
                )
                HorizontalDivider(Modifier.padding(start = Spacing.medium), color = RecitTheme.colors.borderDefault)
            }
        }
    }
}

/** Every copy that is not mine, newest first, as the store orders them. */
class FriendsLatestBooksViewModel(container: AppContainer) : ViewModel() {
    val items: StateFlow<List<ItemRow>> = combine(container.inventory.observeAll(), container.users.myUserId) { items, myId ->
        if (myId == null) emptyList() else items.filter { it.item.ownerId != myId }
    }.stateIn(viewModelScope, SharingStarted.Eagerly, emptyList())
}
