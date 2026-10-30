package studio.lunabee.nouveaurecit.ui.lists

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AddCircle
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.SheetState
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.launch
import studio.lunabee.nouveaurecit.AppContainer
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.SearchResult
import studio.lunabee.nouveaurecit.data.db.ItemRow
import studio.lunabee.nouveaurecit.data.db.WorkEntity
import studio.lunabee.nouveaurecit.data.lists.ListAdditionPlan
import studio.lunabee.nouveaurecit.designsystem.EmptyState
import studio.lunabee.nouveaurecit.designsystem.RecitSearchField
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.SectionHeader
import studio.lunabee.nouveaurecit.designsystem.SheetHeader
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.ui.common.BookRow
import studio.lunabee.nouveaurecit.ui.common.LocalAppContainer
import studio.lunabee.nouveaurecit.ui.search.InventorySearchRanking

/** One work an edition holds, as the reader picks it when the edition holds several — `ListWorkOption`. */
internal data class ListWorkOption(val uri: String, val title: String)

/**
 * `ListAddSearchView` (iOS feature 0060): the sheet « Rechercher » opens over a list — one field, the books
 * on this device first (« Dans mes livres et chez mes amis », five at most), then the works inventaire.io
 * knows. A list of authors asks inventaire.io for authors and nothing else.
 *
 * **One book at a time.** The « + » of a result adds it and closes the sheet; what the list holds carries
 * a check and shows it instead. A copy is added as its work, read from its edition — fetched again when the
 * store has not met its works yet —, and an edition of several works asks which, « Toutes les œuvres »
 * last. Under three characters nothing is asked; a word typed makes one request after 300 ms.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
internal fun ListAddSearchSheet(
    listName: String,
    isAuthor: Boolean,
    existingUris: Set<String>,
    onAdd: (List<String>) -> Unit,
    onShow: (String) -> Unit,
    onDismiss: () -> Unit,
) {
    val container: AppContainer = LocalAppContainer.current
    val scope: CoroutineScope = rememberCoroutineScope()
    val sheetState: SheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    var query: String by rememberSaveable { mutableStateOf("") }
    val trimmed: String = query.trim()
    var remote: RemoteResults by remember { mutableStateOf(RemoteResults.Idle) }
    var resolvingItemId: String? by remember { mutableStateOf(null) }
    var choice: List<ListWorkOption>? by remember { mutableStateOf(null) }

    val itemsFlow: Flow<List<ItemRow>> = remember(container) { container.inventory.observeAll() }
    val items: List<ItemRow> by itemsFlow.collectAsState(initial = emptyList())
    val myUserId: String? by container.users.myUserId.collectAsState()
    val localItems: List<ItemRow> = if (isAuthor || trimmed.length < THRESHOLD || myUserId == null) {
        emptyList()
    } else {
        remember(items, trimmed, myUserId) { InventorySearchRanking.rankItems(items, trimmed, myUserId.orEmpty(), LOCAL_LIMIT).items }
    }

    fun finish(uris: List<String>) {
        when (val plan: ListAdditionPlan = ListAdditionPlan.plan(uris, existingUris)) {
            is ListAdditionPlan.Add -> onAdd(plan.uris)
            is ListAdditionPlan.AlreadyInList -> onShow(plan.uri)
            ListAdditionPlan.Nothing -> return
        }
        onDismiss()
    }

    fun add(row: ItemRow) {
        val editionUri: String = row.item.editionUri
        scope.launch {
            resolvingItemId = row.item.id
            val works: List<WorkEntity> = try {
                worksOf(container, editionUri)
            } catch (cancellation: CancellationException) {
                throw cancellation
            } catch (_: Exception) {
                emptyList()
            } finally {
                resolvingItemId = null
            }
            val options: List<ListWorkOption> = works.map { ListWorkOption(it.uri, it.title) }
            if (options.size > 1) choice = options else finish(options.map { it.uri })
        }
    }

    LaunchedEffect(trimmed) {
        if (trimmed.length < THRESHOLD) {
            remote = RemoteResults.Idle
            return@LaunchedEffect
        }
        remote = RemoteResults.Loading
        delay(DEBOUNCE_MILLIS)
        remote = try {
            val type: SearchResult.Type = if (isAuthor) SearchResult.Type.Humans else SearchResult.Type.Works
            RemoteResults.Loaded(container.search.search(trimmed, setOf(type)))
        } catch (cancellation: CancellationException) {
            throw cancellation
        } catch (_: Exception) {
            RemoteResults.Failed
        }
    }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState,
        containerColor = RecitTheme.colors.backgroundRaised,
    ) {
        Column(Modifier.fillMaxSize().imePadding()) {
            SheetHeader(
                title = stringResource(R.string.list_add_title, listName),
                closeLabel = stringResource(R.string.action_close),
                onClose = onDismiss,
                modifier = Modifier.padding(horizontal = Spacing.medium),
            )
            RecitSearchField(
                query = query,
                onQueryChange = { query = it },
                placeholder = stringResource(if (isAuthor) R.string.list_add_search_prompt_author else R.string.list_add_search_prompt_work),
                clearLabel = stringResource(R.string.lists_search_clear),
                autoCorrect = false,
                modifier = Modifier.padding(horizontal = Spacing.medium, vertical = Spacing.small),
            )
            LazyColumn(Modifier.fillMaxSize()) {
                if (trimmed.length < THRESHOLD) {
                    item(key = "explanation") {
                        EmptyState(
                            title = stringResource(if (isAuthor) R.string.list_add_search_title_author else R.string.list_add_search_title_work),
                            message = stringResource(
                                if (isAuthor) R.string.list_add_search_explanation_author else R.string.list_add_search_explanation_work,
                            ),
                            icon = Icons.Default.Search,
                            modifier = Modifier.fillMaxWidth().padding(vertical = Spacing.large),
                        )
                    }
                } else {
                    if (localItems.isNotEmpty()) {
                        item(key = "local-header") { SectionHeader(stringResource(R.string.list_add_search_local)) }
                        items(localItems, key = { "local.${it.item.id}" }) { row ->
                            ListAddResultRow(
                                title = row.title,
                                subtitle = if (row.item.ownerId == myUserId) {
                                    stringResource(R.string.list_add_mine)
                                } else {
                                    stringResource(R.string.list_add_owner, row.owner?.username.orEmpty())
                                },
                                imageUrl = row.image,
                                isPerson = false,
                                isInList = row.editionWorks?.works.orEmpty().any { it.work.uri in existingUris },
                                isBusy = resolvingItemId == row.item.id,
                                onAdd = { add(row) },
                            )
                        }
                    }
                    item(key = "remote-header") {
                        SectionHeader(stringResource(if (isAuthor) R.string.list_add_search_humans else R.string.list_add_search_works))
                    }
                    when (val state: RemoteResults = remote) {
                        RemoteResults.Idle, RemoteResults.Loading -> item(key = "remote-loading") {
                            Box(Modifier.fillMaxWidth().padding(Spacing.medium), contentAlignment = Alignment.Center) {
                                CircularProgressIndicator(color = RecitTheme.colors.foregroundSecondary)
                            }
                        }
                        RemoteResults.Failed -> item(key = "remote-failed") { RemoteNote(stringResource(R.string.list_add_search_error)) }
                        is RemoteResults.Loaded -> if (state.results.isEmpty()) {
                            item(key = "remote-empty") { RemoteNote(stringResource(R.string.list_add_search_empty)) }
                        } else {
                            items(state.results, key = { "remote.${it.id}" }) { result ->
                                ListAddResultRow(
                                    title = result.label,
                                    subtitle = result.description,
                                    imageUrl = result.image,
                                    isPerson = isAuthor,
                                    isInList = result.uri in existingUris,
                                    isBusy = false,
                                    onAdd = { finish(listOf(result.uri)) },
                                )
                            }
                        }
                    }
                }
            }
        }
    }

    choice?.let { works ->
        ListWorkChoiceDialog(
            listName = listName,
            works = works,
            onChoose = { uris ->
                choice = null
                finish(uris)
            },
            onDismiss = { choice = null },
        )
    }
}

/** The works an edition holds, read again when the store has not met them yet: a copy synced from a snapshot often arrives without. */
internal suspend fun worksOf(container: AppContainer, editionUri: String): List<WorkEntity> {
    var uris: List<String> = container.entities.entities.workUris(editionUri)
    if (uris.isEmpty()) {
        container.entities.refreshEdition(editionUri)
        uris = container.entities.entities.workUris(editionUri)
    }
    val byUri: Map<String, WorkEntity> = container.entities.entities.works(uris).associateBy { it.uri }
    return uris.mapNotNull { byUri[it] }
}

/** « Ce livre réunit plusieurs œuvres » — each work, then « Toutes les œuvres ». */
@Composable
internal fun ListWorkChoiceDialog(
    listName: String,
    works: List<ListWorkOption>,
    onChoose: (List<String>) -> Unit,
    onDismiss: () -> Unit,
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(stringResource(R.string.list_add_choose_title)) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(Spacing.xSmall)) {
                Text(stringResource(R.string.list_add_choose_message, listName), style = RecitTheme.typography.content300)
                works.forEach { work ->
                    TextButton(onClick = { onChoose(listOf(work.uri)) }) { Text(work.title, color = RecitTheme.colors.foregroundTinted) }
                }
                TextButton(onClick = { onChoose(works.map { it.uri }) }) {
                    Text(stringResource(R.string.list_add_choose_all), color = RecitTheme.colors.foregroundTinted)
                }
            }
        },
        confirmButton = {},
        dismissButton = { TextButton(onClick = onDismiss) { Text(stringResource(R.string.action_cancel)) } },
        containerColor = RecitTheme.colors.backgroundRaised,
    )
}

/** `ListAddResultRow`: a book or an author, and at its right a « + » — or a check when the list holds it. */
@Composable
private fun ListAddResultRow(
    title: String,
    subtitle: String?,
    imageUrl: String?,
    isPerson: Boolean,
    isInList: Boolean,
    isBusy: Boolean,
    onAdd: () -> Unit,
) {
    BookRow(
        title = title,
        imageUrl = imageUrl,
        onClick = onAdd,
        subtitle = subtitle,
        isPerson = isPerson,
        trailing = {
            when {
                isBusy -> CircularProgressIndicator(color = RecitTheme.colors.foregroundSecondary, strokeWidth = 2.dp, modifier = Modifier.size(20.dp))
                isInList -> Icon(
                    Icons.Default.CheckCircle,
                    contentDescription = stringResource(R.string.list_add_in_list),
                    tint = RecitTheme.colors.foregroundSecondary,
                )
                else -> IconButton(onClick = onAdd) {
                    Icon(Icons.Default.AddCircle, contentDescription = stringResource(R.string.list_add_action), tint = RecitTheme.colors.foregroundTinted)
                }
            }
        },
    )
}

@Composable
private fun RemoteNote(text: String) {
    Text(
        text,
        style = RecitTheme.typography.content300,
        color = RecitTheme.colors.foregroundSecondary,
        modifier = Modifier.padding(horizontal = Spacing.medium, vertical = Spacing.small),
    )
}

private sealed interface RemoteResults {
    data object Idle : RemoteResults

    data object Loading : RemoteResults

    data class Loaded(val results: List<SearchResult>) : RemoteResults

    data object Failed : RemoteResults
}

/** Matches past this many characters, as in Recherche. */
private const val THRESHOLD: Int = 3

/** How many of my books and my friends' are shown above inventaire.io's answer. */
private const val LOCAL_LIMIT: Int = 5

private const val DEBOUNCE_MILLIS: Long = 300
