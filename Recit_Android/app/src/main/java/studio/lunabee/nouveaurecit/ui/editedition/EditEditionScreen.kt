package studio.lunabee.nouveaurecit.ui.editedition

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ErrorOutline
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Scaffold
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.creation.EditionEdit
import studio.lunabee.nouveaurecit.data.creation.EditionProperty
import studio.lunabee.nouveaurecit.data.creation.EntitySearchHit
import studio.lunabee.nouveaurecit.data.creation.WorkCandidate
import studio.lunabee.nouveaurecit.data.creation.WorkEdit
import studio.lunabee.nouveaurecit.designsystem.EmptyState
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.ui.common.RecitTopBar
import studio.lunabee.nouveaurecit.ui.common.recitViewModel
import studio.lunabee.nouveaurecit.ui.navigation.Destination
import studio.lunabee.nouveaurecit.ui.navigation.Navigator

/**
 * `EditEditionFlowView` + `EditEditionView` (iOS features 0049, 0050): « Modifier l'édition », pushed by
 * the book screen's « Données bibliographiques ». Everything inventaire.io holds about the edition, read
 * fresh, then the form, and what it pushes over itself — as pages of its view model under one
 * [BackHandler], as « Nouveau livre » does.
 *
 * « Enregistrer » is pinned at the foot and waits for the server; while it does, nothing can be left or
 * changed — the save's answer is the draft from then on.
 */
@Composable
fun EditEditionScreen(destination: Destination.EditEdition, navigator: Navigator) {
    val viewModel: EditEditionViewModel = recitViewModel(key = "edit-edition:${destination.uri}") { EditEditionViewModel(it, destination.uri) }
    val state: EditEditionUiState by viewModel.state.collectAsStateWithLifecycle()
    val entitySearch: SearchState<EntitySearchHit> by viewModel.entitySearch.state.collectAsStateWithLifecycle()
    val workSearch: SearchState<WorkCandidate> by viewModel.workSearch.state.collectAsStateWithLifecycle()

    LaunchedEffect(state.isSaved) { if (state.isSaved) navigator.pop() }
    BackHandler(enabled = state.isSaving || !state.pages.isEmpty) { viewModel.back() }

    val edit: EditionEdit? = state.edit
    val page: EditEditionPage? = state.pages.top
    val help: @Composable RowScope.() -> Unit ={ BibliographicDataHelpButton(viewModel::openHelp) }
    when {
        edit == null || page == null -> EditEditionForm(
            state = state,
            viewModel = viewModel,
            onClose = { if (!state.isSaving) navigator.pop() },
        )
        page == EditEditionPage.Help -> BibliographicDataHelpPage(onBack = { viewModel.back() })
        page == EditEditionPage.WorkSearch -> WorkSearchPage(
            title = stringResource(R.string.edit_edition_works_add),
            emptyTitle = stringResource(R.string.edit_edition_work_search_empty_title),
            emptyMessage = stringResource(R.string.edit_edition_work_search_empty_message),
            search = workSearch,
            onQueryChange = viewModel.workSearch::setQuery,
            onChoose = viewModel::addWork,
            onCreate = viewModel::startNewWork,
            onHelp = viewModel::openHelp,
            onBack = { viewModel.back() },
        )
        page is EditEditionPage.WorkDetail -> {
            val work: WorkEdit? = state.work(page.id)
            if (work != null) {
                EditWorkPage(
                    work = work,
                    onTitle = { viewModel.setWorkTitle(page.id, it) },
                    onRemoveAuthor = { viewModel.removeAuthor(page.id, it) },
                    onAddAuthor = { viewModel.openAuthorSearch(page.id) },
                    onHelp = viewModel::openHelp,
                    onBack = { viewModel.back() },
                )
            } else {
                // The work is gone from the form: its page has nothing left to show.
                LaunchedEffect(page) { viewModel.back() }
            }
        }
        page is EditEditionPage.WorkAuthor -> AuthorSearchPage(
            search = entitySearch,
            onQueryChange = viewModel.entitySearch::setQuery,
            onChoose = { viewModel.addAuthor(page.id, it) },
            onBack = { viewModel.back() },
            actions = help,
        )
        page is EditEditionPage.Property -> EditionPropertyPage(
            step = page.step,
            properties = edit.properties,
            onChange = viewModel::setProperties,
            entitySearch = entitySearch,
            onEntityQuery = viewModel.entitySearch::setQuery,
            push = viewModel::pushProperty,
            pop = viewModel::pop,
            actions = help,
        )
    }
}

@Composable
private fun EditEditionForm(state: EditEditionUiState, viewModel: EditEditionViewModel, onClose: () -> Unit) {
    val edit: EditionEdit? = state.edit
    Scaffold(
        topBar = {
            RecitTopBar(
                title = stringResource(R.string.edit_edition_title),
                onBack = onClose,
                actions = { if (edit != null) BibliographicDataHelpButton(viewModel::openHelp) },
            )
        },
        bottomBar = {
            if (edit != null) {
                FormActionBar(
                    text = stringResource(if (state.failure?.isWorthRetrying == true) R.string.create_book_retry else R.string.action_save),
                    onClick = viewModel::save,
                    enabled = edit.isSaveable,
                    isLoading = state.isSaving,
                )
            }
        },
        containerColor = RecitTheme.colors.backgroundGrouped,
    ) { padding ->
        Box(Modifier.padding(padding).fillMaxSize()) {
            when (state.phase) {
                EditEditionPhase.Loading -> CircularProgressIndicator(
                    color = RecitTheme.colors.foregroundSecondary,
                    modifier = Modifier.align(Alignment.Center),
                )
                EditEditionPhase.Failed -> EmptyState(
                    title = stringResource(R.string.book_resolve_error_title),
                    message = stringResource(R.string.book_resolve_error_message),
                    icon = Icons.Filled.ErrorOutline,
                    actionTitle = stringResource(R.string.action_retry),
                    onAction = viewModel::load,
                    modifier = Modifier.align(Alignment.Center),
                )
                EditEditionPhase.Loaded -> if (edit != null) EditEditionSections(state, edit, viewModel)
            }
            if (state.isSaving) SavingShield()
        }
    }
}

/** `EditEditionView`'s sections, in iOS 0050's order. */
@Composable
private fun EditEditionSections(state: EditEditionUiState, edit: EditionEdit, viewModel: EditEditionViewModel) {
    LazyColumn(
        modifier = Modifier.fillMaxSize().imePadding(),
        contentPadding = PaddingValues(top = Spacing.small, bottom = Spacing.large),
        verticalArrangement = Arrangement.spacedBy(Spacing.xSmall),
    ) {
        state.failure?.let { failure ->
            item(key = "failure") {
                FormFailureBanner(title = stringResource(EditionPropertyLabels.editTitle(failure)), body = stringResource(EditionPropertyLabels.editBody(failure)))
            }
        }
        item(key = "notice") { BibliographicDataNotice(onLearnMore = viewModel::openHelp) }
        item(key = "works") {
            EditionWorksSection(works = edit.works, onOpen = viewModel::openWork, onDetach = viewModel::detachWork, onAdd = viewModel::openWorkSearch)
        }
        item(key = "cover") {
            EditionCoverSection(
                isbn = edit.original.isbn,
                isbnLabel = stringResource(if (edit.original.isbn10 == null) R.string.edit_edition_isbn else R.string.edit_edition_isbn13),
                isbn10 = edit.original.isbn10,
                coverPath = edit.coverPath,
                coverUrl = edit.coverUrl,
                onCover = viewModel::setCover,
            )
        }
        item(key = "title") {
            EditionTitleSection(title = edit.title, subtitle = edit.subtitle, onTitle = viewModel::setTitle, onSubtitle = viewModel::setSubtitle)
        }
        item(key = "publication") { EditionPublicationSection(properties = edit.properties, onOpen = viewModel::openProperty) }
        item(key = "format") { EditionFormatSection(properties = edit.properties, onChange = viewModel::setProperties) }
        item(key = "contributors") { EditionContributorsSection(properties = edit.properties, onOpen = viewModel::openProperty) }
        item(key = "databases") {
            EditionIdentifiersSection(
                group = EditionProperty.Group.Databases,
                properties = edit.properties,
                onChange = viewModel::setProperties,
                onAdd = { viewModel.openIdentifierCatalog(EditionProperty.Group.Databases) },
            )
        }
        item(key = "links") {
            EditionIdentifiersSection(
                group = EditionProperty.Group.Links,
                properties = edit.properties,
                onChange = viewModel::setProperties,
                onAdd = { viewModel.openIdentifierCatalog(EditionProperty.Group.Links) },
            )
        }
    }
}

/** Over the form while it saves: nothing is touched until the server has answered. */
@Composable
private fun SavingShield() {
    val interaction: MutableInteractionSource = remember { MutableInteractionSource() }
    Box(Modifier.fillMaxSize().clickable(interactionSource = interaction, indication = null, onClick = {}))
}
