package studio.lunabee.nouveaurecit.ui.book

import android.content.Context
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.db.WorkEntity
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.SectionHeader
import studio.lunabee.nouveaurecit.ui.common.LocalMessenger
import studio.lunabee.nouveaurecit.ui.common.Messenger
import studio.lunabee.nouveaurecit.ui.common.RecitTopBar
import studio.lunabee.nouveaurecit.ui.common.recitViewModel
import studio.lunabee.nouveaurecit.ui.lists.ListFormSheet
import studio.lunabee.nouveaurecit.ui.navigation.BookAnchor
import studio.lunabee.nouveaurecit.ui.navigation.Destination
import studio.lunabee.nouveaurecit.ui.navigation.Navigator

/**
 * `WorkEditionGatewayView` + `WorkEditionPicker`: a work with exactly one edition opens that book
 * in place; with several, the picker — « Éditions », the work's header, summary and authors, and
 * « Éditions de %s », each row opening that edition.
 */
@Composable
fun WorkScreen(destination: Destination.Work, navigator: Navigator) {
    val viewModel: WorkViewModel = recitViewModel(key = "work:${destination.uri}") { WorkViewModel(it, destination.uri) }
    val state: WorkUiState by viewModel.state.collectAsStateWithLifecycle()

    val single: String? = state.singleEditionUri
    if (single != null) {
        BookDetail(anchor = BookAnchor.Edition(single), navigator = navigator)
    } else {
        EditionPicker(state, viewModel, navigator)
    }
}

@Composable
private fun EditionPicker(state: WorkUiState, viewModel: WorkViewModel, navigator: Navigator) {
    val messenger: Messenger = LocalMessenger.current
    val context: Context = LocalContext.current
    val scope: CoroutineScope = rememberCoroutineScope()
    var createsList: Boolean by rememberSaveable { mutableStateOf(false) }

    Scaffold(
        topBar = {
            RecitTopBar(
                title = stringResource(R.string.nav_editions),
                onBack = navigator::pop,
                actions = {
                    if (state.work != null) {
                        MoreActionsMenu(
                            listOf(
                                listMenuLine(
                                    context = context,
                                    entries = state.myLists,
                                    onToggle = { entry ->
                                        scope.launch { if (viewModel.toggleList(entry)) messenger.show(membershipMessage(context, entry)) }
                                    },
                                    onCreate = { createsList = true },
                                ),
                            ),
                        )
                    }
                },
            )
        },
        containerColor = RecitTheme.colors.backgroundSecondary,
    ) { padding: PaddingValues ->
        Box(Modifier.fillMaxSize().padding(padding)) {
            val work: WorkEntity? = state.work
            val phase: WorkPhase = state.phase
            when {
                phase is WorkPhase.Error && work == null -> Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Text(
                        stringResource(R.string.error_with_message, phase.message ?: stringResource(R.string.error_generic)),
                        style = RecitTheme.typography.content300,
                        color = RecitTheme.colors.foregroundSecondary,
                    )
                }
                work == null -> Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator(color = RecitTheme.colors.foregroundSecondary)
                }
                else -> WorkContent(work, state, navigator)
            }
        }
    }

    if (createsList) {
        ListFormSheet(listId = null, fileWorkUri = state.work?.uri, onDismiss = { createsList = false })
    }
}

@Composable
private fun WorkContent(work: WorkEntity, state: WorkUiState, navigator: Navigator) {
    val synced: Boolean = (state.phase as? WorkPhase.Loaded)?.editionsSynced == true
    LazyColumn(Modifier.fillMaxSize()) {
        item(key = "header") { EntityHeader(title = work.title, subtitle = work.subtitle, imageUrl = work.image) }
        item(key = "summary") { SummaryRow(state.summary) }
        item(key = "authors") { AuthorsRow(state.authors) { navigator.push(Destination.Author(it)) } }
        item(key = "editions-header") { SectionHeader(title = stringResource(R.string.work_editions_header, work.title)) }
        if (state.editions.isEmpty() && !synced) {
            item(key = "editions-loading") { LoadingCell() }
        }
        items(state.editions, key = { it.uri }) { edition ->
            EntityResultRow(title = edition.title, subtitle = edition.subtitle, imageUrl = edition.image) {
                navigator.push(Destination.Book(BookAnchor.Edition(edition.uri)))
            }
        }
    }
}
