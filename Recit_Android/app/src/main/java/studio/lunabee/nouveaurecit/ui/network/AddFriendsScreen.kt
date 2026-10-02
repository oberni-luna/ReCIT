package studio.lunabee.nouveaurecit.ui.network

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Close
import androidx.compose.material.icons.rounded.Search
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import studio.lunabee.nouveaurecit.AppContainer
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.SyncStatus
import studio.lunabee.nouveaurecit.data.db.UserEntity
import studio.lunabee.nouveaurecit.data.model.UserRelation
import studio.lunabee.nouveaurecit.designsystem.CornerRadius
import studio.lunabee.nouveaurecit.designsystem.EmptyState
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.SectionHeader
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.ui.common.RecitTopBar
import studio.lunabee.nouveaurecit.ui.common.recitViewModel
import studio.lunabee.nouveaurecit.ui.navigation.Destination
import studio.lunabee.nouveaurecit.ui.navigation.Navigator

class AddFriendsViewModel(private val container: AppContainer) : ViewModel() {
    private val _state: MutableStateFlow<ReaderSearchState> = MutableStateFlow(ReaderSearchState())
    val state: StateFlow<ReaderSearchState> = _state.asStateFlow()

    /** The requests I sent and nobody has answered yet — cancelling one elsewhere empties it here. */
    val pending: StateFlow<List<UserEntity>> = container.users.observeByRelation(UserRelation.RequestSent)
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    /**
     * The results, read back live from Room in the server's order: tapping « Ajouter » flips the
     * row's relation in the store, and the tag replaces the pill at once.
     */
    val results: StateFlow<List<UserEntity>> = _state
        .map { it.resultIds }
        .distinctUntilChanged()
        .flatMapLatest { ids ->
            if (ids.isEmpty()) {
                flowOf(emptyList())
            } else {
                combine(ids.map(container.users::observeUser)) { users -> users.filterNotNull() }
            }
        }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    val firstSyncProgress: StateFlow<Map<String, SyncStatus.Progress>> = container.syncStatus.firstSyncProgress

    val actions: RelationActions = RelationActions(container, viewModelScope)

    private var searchJob: Job? = null

    /** `.task(id: query)`: each keystroke cancels the previous search, which waits 350 ms first. */
    fun onQueryChange(query: String) {
        _state.update { it.copy(query = query) }
        searchJob?.cancel()
        val trimmed: String = query.trim()
        if (trimmed.isEmpty()) {
            _state.update { it.copy(resultIds = emptyList(), isSearching = false, hasSearched = false) }
            return
        }
        searchJob = viewModelScope.launch {
            delay(SEARCH_DEBOUNCE_MILLIS)
            _state.update { it.copy(isSearching = true) }
            try {
                val ids: List<String> = container.users.searchReaders(trimmed).map { it.id }
                _state.update { it.copy(resultIds = ids, hasSearched = true, isSearching = false) }
            } catch (cancellation: CancellationException) {
                throw cancellation
            } catch (_: Exception) {
                // A failed lookup reads as an empty one: the placeholder is the answer either way.
                _state.update { it.copy(resultIds = emptyList(), hasSearched = true, isSearching = false) }
            }
        }
    }

    private companion object {
        const val SEARCH_DEBOUNCE_MILLIS: Long = 350
    }
}

/**
 * `ReaderSearchView`: looking a reader up on inventaire.io by username — the only reader search
 * the server has. At rest it lists the requests already in flight (« Demandes en cours »); from
 * the first character typed they go, so nobody stands twice on the screen.
 */
@Composable
fun AddFriendsScreen(navigator: Navigator) {
    val viewModel: AddFriendsViewModel = recitViewModel { AddFriendsViewModel(it) }
    val state: ReaderSearchState by viewModel.state.collectAsStateWithLifecycle()
    val pendingAll: List<UserEntity> by viewModel.pending.collectAsStateWithLifecycle()
    val results: List<UserEntity> by viewModel.results.collectAsStateWithLifecycle()
    val progress: Map<String, SyncStatus.Progress> by viewModel.firstSyncProgress.collectAsStateWithLifecycle()
    val pending: List<UserEntity> = if (state.isQuerying) emptyList() else pendingAll

    Scaffold(
        topBar = {
            Column {
                RecitTopBar(title = stringResource(R.string.network_add_friends), onBack = navigator::pop)
                SearchField(query = state.query, onQueryChange = viewModel::onQueryChange)
            }
        },
        containerColor = RecitTheme.colors.backgroundSecondary,
    ) { padding ->
        LazyColumn(
            modifier = Modifier.fillMaxSize().padding(padding),
            contentPadding = PaddingValues(bottom = Spacing.large),
        ) {
            if (pending.isNotEmpty()) {
                item(key = "pending-header") {
                    SectionHeader(stringResource(R.string.network_requests_pending), Modifier.padding(horizontal = Spacing.medium))
                }
                item(key = "pending") {
                    ReaderSection(pending, progress, navigator, viewModel.actions)
                }
            }

            if (results.isNotEmpty()) {
                item(key = "results-header") {
                    SectionHeader(stringResource(R.string.network_search_header), Modifier.padding(horizontal = Spacing.medium))
                }
                item(key = "results") {
                    ReaderSection(results, progress, navigator, viewModel.actions)
                }
            } else if (state.showsPlaceholder(pending.size)) {
                item(key = "placeholder") {
                    SearchPlaceholder(state)
                }
            }
        }
    }
}

@Composable
private fun SearchField(query: String, onQueryChange: (String) -> Unit) {
    TextField(
        value = query,
        onValueChange = onQueryChange,
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = Spacing.medium, vertical = Spacing.small),
        placeholder = { Text(stringResource(R.string.network_search_prompt), style = RecitTheme.typography.content300) },
        leadingIcon = { Icon(Icons.Rounded.Search, contentDescription = null) },
        trailingIcon = {
            if (query.isNotEmpty()) {
                IconButton(onClick = { onQueryChange("") }) {
                    Icon(Icons.Rounded.Close, contentDescription = stringResource(R.string.network_search_clear))
                }
            }
        },
        singleLine = true,
        textStyle = RecitTheme.typography.content300,
        keyboardOptions = KeyboardOptions(
            capitalization = KeyboardCapitalization.None,
            autoCorrectEnabled = false,
            imeAction = ImeAction.Search,
        ),
        shape = RoundedCornerShape(CornerRadius.rounded),
        colors = TextFieldDefaults.colors(
            focusedContainerColor = RecitTheme.colors.backgroundDefault,
            unfocusedContainerColor = RecitTheme.colors.backgroundDefault,
            focusedIndicatorColor = RecitTheme.colors.backgroundDefault,
            unfocusedIndicatorColor = RecitTheme.colors.backgroundDefault,
            cursorColor = RecitTheme.colors.foregroundTinted,
            focusedTextColor = RecitTheme.colors.foregroundDefault,
            unfocusedTextColor = RecitTheme.colors.foregroundDefault,
            focusedPlaceholderColor = RecitTheme.colors.foregroundPlaceholder,
            unfocusedPlaceholderColor = RecitTheme.colors.foregroundPlaceholder,
            focusedLeadingIconColor = RecitTheme.colors.foregroundSecondary,
            unfocusedLeadingIconColor = RecitTheme.colors.foregroundSecondary,
        ),
    )
}

@Composable
private fun ReaderSection(
    users: List<UserEntity>,
    progress: Map<String, SyncStatus.Progress>,
    navigator: Navigator,
    actions: RelationActions,
) {
    SectionCard {
        users.forEachIndexed { index, user ->
            if (index > 0) HorizontalDivider(color = RecitTheme.colors.borderDefault)
            ReaderRow(
                user = user,
                syncState = FirstSyncState.of(user.lastInventorySync, progress[user.id]),
                onOpen = { navigator.push(Destination.User(user.id)) },
                onAdd = { actions.request(user.id) },
            )
        }
    }
}

@Composable
private fun SearchPlaceholder(state: ReaderSearchState) {
    when (state.placeholder) {
        ReaderSearchPlaceholder.Searching -> Column(
            modifier = Modifier.fillMaxWidth().padding(vertical = Spacing.xLarge),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            CircularProgressIndicator(color = RecitTheme.colors.foregroundTinted)
        }
        ReaderSearchPlaceholder.NoResults -> EmptyState(
            title = stringResource(R.string.network_search_no_results),
            message = stringResource(R.string.network_search_no_results_message, state.query.trim()),
            icon = Icons.Rounded.Search,
            modifier = Modifier.fillMaxWidth().padding(vertical = Spacing.large),
        )
        ReaderSearchPlaceholder.Initial -> EmptyState(
            title = stringResource(R.string.network_search_title),
            message = stringResource(R.string.network_search_explanation),
            icon = Icons.Rounded.Search,
            modifier = Modifier.fillMaxWidth().padding(vertical = Spacing.large),
        )
    }
}
