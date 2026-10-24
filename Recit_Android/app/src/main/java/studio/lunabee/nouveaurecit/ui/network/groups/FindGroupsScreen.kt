package studio.lunabee.nouveaurecit.ui.network.groups

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Search
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Scaffold
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import studio.lunabee.nouveaurecit.AppContainer
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.groups.GroupSearchResult
import studio.lunabee.nouveaurecit.data.groups.ReaderGroup
import studio.lunabee.nouveaurecit.designsystem.EmptyState
import studio.lunabee.nouveaurecit.designsystem.RecitSearchField
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.SectionHeader
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.ui.common.RecitTopBar
import studio.lunabee.nouveaurecit.ui.common.recitViewModel
import studio.lunabee.nouveaurecit.ui.navigation.Destination
import studio.lunabee.nouveaurecit.ui.navigation.Navigator
import studio.lunabee.nouveaurecit.ui.network.SectionCard
import kotlin.coroutines.cancellation.CancellationException

class FindGroupsViewModel(private val container: AppContainer) : ViewModel() {
    private val _state: MutableStateFlow<GroupSearchState> = MutableStateFlow(GroupSearchState())
    val state: StateFlow<GroupSearchState> = _state.asStateFlow()

    /** The groups this launch knows: a result I already stand in carries its tag. */
    val knownGroups: StateFlow<Map<String, ReaderGroup>> = container.groups.groups

    val myUserId: StateFlow<String?> = container.users.myUserId

    private var searchJob: Job? = null

    /** `.task(id: query)`: each keystroke cancels the previous search, which waits 350 ms first. */
    fun onQueryChange(query: String) {
        _state.update { it.copy(query = query) }
        searchJob?.cancel()
        val trimmed: String = query.trim()
        if (trimmed.isEmpty()) {
            _state.update { it.copy(results = emptyList(), isSearching = false, hasSearched = false) }
            return
        }
        searchJob = viewModelScope.launch {
            delay(SEARCH_DEBOUNCE_MILLIS)
            _state.update { it.copy(isSearching = true) }
            try {
                val results: List<GroupSearchResult> = container.groups.searchGroups(trimmed)
                _state.update { it.copy(results = results, hasSearched = true, isSearching = false) }
            } catch (cancellation: CancellationException) {
                throw cancellation
            } catch (_: Exception) {
                // A failed lookup reads as an empty one: the placeholder is the answer either way.
                _state.update { it.copy(results = emptyList(), hasSearched = true, isSearching = false) }
            }
        }
    }

    private companion object {
        const val SEARCH_DEBOUNCE_MILLIS: Long = 350
    }
}

/**
 * `FindGroupsView`: looking a group up by name, built like the reader search — a field always on
 * screen, a pause before each request, the server's ranking kept.
 *
 * **No « Rejoindre » in the row.** The search answers a name and a description, and nothing about
 * whether the group is open: a button here could not say whether it lets you in or only asks. The
 * row opens the group, whose screen has read the document and offers the right one.
 */
@Composable
fun FindGroupsScreen(navigator: Navigator) {
    val viewModel: FindGroupsViewModel = recitViewModel { FindGroupsViewModel(it) }
    val state: GroupSearchState by viewModel.state.collectAsStateWithLifecycle()
    val known: Map<String, ReaderGroup> by viewModel.knownGroups.collectAsStateWithLifecycle()
    val myUserId: String? by viewModel.myUserId.collectAsStateWithLifecycle()

    Scaffold(
        topBar = {
            Column {
                RecitTopBar(title = stringResource(R.string.groups_find), onBack = navigator::pop)
                RecitSearchField(
                    query = state.query,
                    onQueryChange = viewModel::onQueryChange,
                    placeholder = stringResource(R.string.groups_search_prompt),
                    clearLabel = stringResource(R.string.network_search_clear),
                    autoCorrect = false,
                    modifier = Modifier.padding(horizontal = Spacing.medium, vertical = Spacing.small),
                )
            }
        },
        containerColor = RecitTheme.colors.backgroundDefault,
    ) { padding ->
        LazyColumn(
            modifier = Modifier.fillMaxSize().padding(padding),
            contentPadding = PaddingValues(bottom = Spacing.large),
        ) {
            if (state.results.isEmpty()) {
                item(key = "placeholder") { SearchPlaceholder(state) }
            } else {
                item(key = "results-header") { SectionHeader(stringResource(R.string.groups_search_header)) }
                item(key = "results") {
                    SectionCard {
                        state.results.forEachIndexed { index, result ->
                            if (index > 0) RowDivider()
                            GroupRow(
                                name = result.name,
                                pictureUrl = result.pictureUrl,
                                detail = result.description,
                                role = known[result.id]?.role(of = myUserId),
                                onClick = { navigator.push(Destination.Group(result.id)) },
                            )
                        }
                    }
                }
                item(key = "footer") {
                    GroupNote(
                        text = stringResource(R.string.groups_search_footer),
                        modifier = Modifier.padding(horizontal = Spacing.medium, vertical = Spacing.small),
                    )
                }
            }
        }
    }
}

@Composable
private fun SearchPlaceholder(state: GroupSearchState) {
    when (state.placeholder) {
        GroupSearchPlaceholder.Searching -> Column(
            modifier = Modifier.fillMaxWidth().padding(vertical = Spacing.xLarge),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            CircularProgressIndicator(color = RecitTheme.colors.foregroundTinted)
        }
        GroupSearchPlaceholder.NoResults -> EmptyState(
            title = stringResource(R.string.groups_search_no_results),
            message = stringResource(R.string.groups_search_no_results_message, state.query.trim()),
            icon = Icons.Rounded.Search,
            modifier = Modifier.fillMaxWidth().padding(vertical = Spacing.large),
        )
        GroupSearchPlaceholder.Initial -> EmptyState(
            title = stringResource(R.string.groups_search_title),
            message = stringResource(R.string.groups_search_explanation),
            icon = Icons.Rounded.Search,
            modifier = Modifier.fillMaxWidth().padding(vertical = Spacing.large),
        )
    }
}
