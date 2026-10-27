package studio.lunabee.nouveaurecit.ui.createbook

import androidx.activity.compose.BackHandler
import androidx.annotation.StringRes
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.selection.selectable
import androidx.compose.material3.RadioButton
import androidx.compose.material3.RadioButtonDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import studio.lunabee.nouveaurecit.AppContainer
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.creation.CreateBookFailure
import studio.lunabee.nouveaurecit.data.creation.EditionProperty
import studio.lunabee.nouveaurecit.data.creation.EntitySearchHit
import studio.lunabee.nouveaurecit.data.creation.NewBookDraft
import studio.lunabee.nouveaurecit.data.creation.WorkCandidate
import studio.lunabee.nouveaurecit.data.db.AuthorEntity
import studio.lunabee.nouveaurecit.data.db.WorkEntity
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.SecondaryButton
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.ui.common.LocalAppContainer
import studio.lunabee.nouveaurecit.ui.common.RecitTopBar
import studio.lunabee.nouveaurecit.ui.editedition.AuthorSearchPage
import studio.lunabee.nouveaurecit.ui.editedition.BibliographicDataHelpButton
import studio.lunabee.nouveaurecit.ui.editedition.BibliographicDataHelpPage
import studio.lunabee.nouveaurecit.ui.editedition.BibliographicDataNotice
import studio.lunabee.nouveaurecit.ui.editedition.EditWorkPage
import studio.lunabee.nouveaurecit.ui.editedition.EditionContributorsSection
import studio.lunabee.nouveaurecit.ui.editedition.EditionCoverSection
import studio.lunabee.nouveaurecit.ui.editedition.EditionFormatSection
import studio.lunabee.nouveaurecit.ui.editedition.EditionIdentifiersSection
import studio.lunabee.nouveaurecit.ui.editedition.EditionPropertyPage
import studio.lunabee.nouveaurecit.ui.editedition.EditionPublicationSection
import studio.lunabee.nouveaurecit.ui.editedition.EditionTitleSection
import studio.lunabee.nouveaurecit.ui.editedition.FormActionBar
import studio.lunabee.nouveaurecit.ui.editedition.FormActionRow
import studio.lunabee.nouveaurecit.ui.editedition.FormFailureBanner
import studio.lunabee.nouveaurecit.ui.editedition.FormFootnote
import studio.lunabee.nouveaurecit.ui.editedition.FormPageScaffold
import studio.lunabee.nouveaurecit.ui.editedition.FormSection
import studio.lunabee.nouveaurecit.ui.editedition.SavingShield
import studio.lunabee.nouveaurecit.ui.editedition.SearchState
import studio.lunabee.nouveaurecit.ui.editedition.SwipeToRemoveRow
import studio.lunabee.nouveaurecit.ui.editedition.WorkRow
import studio.lunabee.nouveaurecit.ui.editedition.WorkSearchPage

/**
 * `NewBookFlowView` (features 0020, iOS 0047 and 0050): what a scan which found nothing turns into — a
 * contribution to inventaire.io. It opens on the search for the work; « Nouvelle édition » is the edition's
 * form, the same sections as « Modifier l'édition »; « Nouvelle œuvre », « Œuvre déjà connue », the
 * property pages and the help are pushed over it, as pages of [CreateBookSession] under one [BackHandler].
 *
 * Drawn by the camera in place of its feed, the way iOS poses a sheet on it: the flow's back stack
 * belongs to the book screen a row can open, and the two paths must not braid.
 *
 * Publishing waits for the server, and nothing can be left or changed while it does — a half-heard
 * publication is the one way to make a duplicate. A failure is said on the page that published, beside
 * the button that retries, not on the shared snackbar.
 */
@Composable
fun CreateBookScreen(session: CreateBookSession, onClose: () -> Unit) {
    val state: CreateBookState by session.state.collectAsStateWithLifecycle()
    val workSearch: SearchState<WorkCandidate> by session.workSearch.state.collectAsStateWithLifecycle()
    val entitySearch: SearchState<EntitySearchHit> by session.entitySearch.state.collectAsStateWithLifecycle()
    BackHandler {
        if (!session.back()) onClose()
    }
    val close: () -> Unit = { if (!state.isPublishing) onClose() }
    val back: () -> Unit = { session.back() }
    val help: @Composable RowScope.() -> Unit = { BibliographicDataHelpButton(session::openHelp) }
    val draft: NewBookDraft = state.draft
    when (val page: CreateBookPage? = state.pages.top) {
        null -> WorkSearchPage(
            title = stringResource(R.string.create_book_title),
            emptyTitle = stringResource(R.string.create_book_search_empty_title),
            emptyMessage = stringResource(R.string.create_book_search_empty_message, draft.isbn),
            search = workSearch,
            onQueryChange = session.workSearch::setQuery,
            onChoose = session::chooseWork,
            onCreate = session::startNewWork,
            onHelp = session::openHelp,
            onBack = close,
            closes = true,
        )
        CreateBookPage.Edition -> NewEditionPage(state = state, session = session, onClose = close)
        CreateBookPage.NewWork -> EditWorkPage(
            work = CreateBookRules.newWork(draft),
            onTitle = session::setWorkTitle,
            onRemoveAuthor = session::removeAuthor,
            onAddAuthor = session::openNewWorkAuthor,
            onHelp = session::openHelp,
            onBack = back,
            footer = R.string.create_book_new_work_help,
        )
        CreateBookPage.NewWorkAuthor -> AuthorSearchPage(
            search = entitySearch,
            onQueryChange = session.entitySearch::setQuery,
            onChoose = session::addAuthor,
            onBack = back,
            actions = help,
        )
        is CreateBookPage.RecognisedWork -> WorkMatchPage(uri = page.uri, state = state, session = session, onClose = close)
        CreateBookPage.Help -> BibliographicDataHelpPage(onBack = back)
        is CreateBookPage.Property -> EditionPropertyPage(
            step = page.step,
            properties = draft.properties,
            onChange = session::setProperties,
            entitySearch = entitySearch,
            onEntityQuery = session.entitySearch::setQuery,
            push = session::pushProperty,
            pop = session::pop,
            actions = help,
        )
    }
}

/**
 * `NewEditionView`: the book in hand, described with « Modifier l'édition »'s sections — the work found or
 * being described, the cover and the ISBN the camera read, the title (the work's to begin with), and every
 * property inventaire.io accepts on an edition, the language already filled in from the ISBN.
 */
@Composable
private fun NewEditionPage(state: CreateBookState, session: CreateBookSession, onClose: () -> Unit) {
    val draft: NewBookDraft = state.draft
    Scaffold(
        topBar = {
            RecitTopBar(
                title = stringResource(R.string.create_book_edition_title),
                onBack = { session.back() },
                actions = { BibliographicDataHelpButton(session::openHelp) },
            )
        },
        bottomBar = {
            CreateBookPublishBar(state = state, onPublish = session::publish, onClose = onClose)
        },
        containerColor = RecitTheme.colors.backgroundGrouped,
    ) { padding ->
        Box(Modifier.padding(padding).fillMaxSize()) {
            LazyColumn(
                modifier = Modifier.fillMaxSize().imePadding(),
                contentPadding = PaddingValues(top = Spacing.small, bottom = Spacing.large),
                verticalArrangement = Arrangement.spacedBy(Spacing.xSmall),
            ) {
                state.failure?.let { failure -> item(key = "failure") { CreateBookFailureBanner(failure) } }
                item(key = "notice") { BibliographicDataNotice(onLearnMore = session::openHelp) }
                item(key = "work") {
                    NewEditionWorkSection(draft = draft, onFindWork = session::findWork, onOpenNewWork = session::openNewWork, onDetach = session::detachWork)
                }
                item(key = "cover") {
                    EditionCoverSection(
                        isbn = draft.isbn,
                        isbnLabel = stringResource(R.string.create_book_isbn),
                        isbn10 = null,
                        coverPath = draft.coverImagePath,
                        coverUrl = draft.coverImageUrl.takeIf { draft.coverImagePath == null },
                        onCover = session::setCover,
                        footer = editionNotes(draft),
                    )
                }
                item(key = "title") {
                    EditionTitleSection(
                        title = draft.title,
                        subtitle = draft.subtitle,
                        onTitle = session::setTitle,
                        onSubtitle = session::setSubtitle,
                        footer = stringResource(R.string.create_book_edition_title_help),
                    )
                }
                item(key = "publication") { EditionPublicationSection(properties = draft.properties, onOpen = session::openProperty) }
                item(key = "format") { EditionFormatSection(properties = draft.properties, onChange = session::setProperties) }
                item(key = "contributors") { EditionContributorsSection(properties = draft.properties, onOpen = session::openProperty) }
                item(key = "databases") {
                    EditionIdentifiersSection(
                        group = EditionProperty.Group.Databases,
                        properties = draft.properties,
                        onChange = session::setProperties,
                        onAdd = { session.openIdentifierCatalog(EditionProperty.Group.Databases) },
                    )
                }
                item(key = "links") {
                    EditionIdentifiersSection(
                        group = EditionProperty.Group.Links,
                        properties = draft.properties,
                        onChange = session::setProperties,
                        onAdd = { session.openIdentifierCatalog(EditionProperty.Group.Links) },
                    )
                }
            }
            if (state.isPublishing) SavingShield()
        }
    }
}

/**
 * `CreateBookEditionNotes`: the language the ISBN gave, once it has answered — saying nothing is the
 * honest state otherwise — and that what is written here becomes public.
 */
@Composable
private fun editionNotes(draft: NewBookDraft): String {
    val language: String? = draft.language?.displayName()?.let { stringResource(R.string.create_book_language, it) }
    return listOfNotNull(language, stringResource(R.string.create_book_public_notice)).joinToString("\n")
}

/**
 * `NewEditionWorkSection`: « Édition de », the one work the new book is an edition of. A work inventaire.io
 * has is touched to go back to the search for another; one being described is touched to name it and its
 * authors. Either is detached with a swipe, and the section then offers to find one — a book is published
 * as an edition of a work, or not at all.
 */
@Composable
private fun NewEditionWorkSection(draft: NewBookDraft, onFindWork: () -> Unit, onOpenNewWork: () -> Unit, onDetach: () -> Unit) {
    val footer: Int = when (CreateBookRules.workFooter(draft)) {
        CreateBookRules.WorkFooter.Chosen -> R.string.create_book_edition_of_help
        CreateBookRules.WorkFooter.NewWork -> R.string.create_book_edition_new_work_help
        CreateBookRules.WorkFooter.None -> R.string.create_book_edition_no_work_help
    }
    FormSection(header = stringResource(R.string.create_book_edition_of), footer = stringResource(footer)) {
        val detach: String = stringResource(R.string.edit_edition_works_detach)
        val chosen: WorkCandidate? = draft.chosenWork
        when {
            chosen != null -> SwipeToRemoveRow(label = detach, onRemove = onDetach) { WorkRow(work = chosen, onClick = onFindWork) }
            draft.hasWork -> SwipeToRemoveRow(label = detach, onRemove = onDetach) {
                WorkRow(work = CreateBookRules.newWorkCandidate(draft), onClick = onOpenNewWork)
            }
            else -> FormActionRow(title = stringResource(R.string.edit_edition_works_add), onClick = onFindWork)
        }
    }
}

/**
 * `CreateBookPublishFooter`: « Publier et ajouter à mes livres », pinned — and, once something has failed,
 * the way out that keeps the draft. Before that, closing is closing, and a second way out is one too many.
 */
@Composable
private fun CreateBookPublishBar(state: CreateBookState, onPublish: () -> Unit, onClose: () -> Unit) {
    FormActionBar(
        text = stringResource(if (state.failure?.isWorthRetrying == true) R.string.create_book_retry else R.string.create_book_publish),
        onClick = onPublish,
        enabled = state.draft.isPublishable,
        isLoading = state.isPublishing,
    ) {
        if (state.failure != null) {
            SecondaryButton(text = stringResource(R.string.create_book_keep_draft), onClick = onClose, enabled = !state.isPublishing)
        }
    }
}

/** Every failure says first that nothing was created: a user who fears a duplicate does not retry. */
@Composable
private fun CreateBookFailureBanner(failure: CreateBookFailure) {
    @StringRes val title: Int
    @StringRes val body: Int
    when (failure) {
        CreateBookFailure.NeedsAccount -> {
            title = R.string.create_book_failure_account_title
            body = R.string.create_book_failure_account_body
        }
        CreateBookFailure.Refused -> {
            title = R.string.create_book_failure_refused_title
            body = R.string.create_book_failure_refused_body
        }
        CreateBookFailure.Network -> {
            title = R.string.create_book_failure_network_title
            body = R.string.create_book_failure_network_body
        }
    }
    FormFailureBanner(title = stringResource(title), body = stringResource(body))
}

/**
 * `WorkMatchView`: « Œuvre déjà connue » — the search did not offer it, but inventaire.io recognises the
 * work being created by its title and its author. Shown only when the dry run recognised one. The work is
 * read from the store, refreshed as the page opens, so the title shown may differ from the one typed —
 * that is the point of the page; until it is read, the row shows what the user typed.
 */
@Composable
private fun WorkMatchPage(uri: String, state: CreateBookState, session: CreateBookSession, onClose: () -> Unit) {
    val container: AppContainer = LocalAppContainer.current
    val work: WorkEntity? by remember(uri) { container.entities.observeWork(uri) }.collectAsStateWithLifecycle(null)
    val authors: List<AuthorEntity> by remember(uri) {
        container.entities.entities.observeAuthorsOfWorks(listOf(uri))
    }.collectAsStateWithLifecycle(emptyList())
    val draft: NewBookDraft = state.draft
    val candidate: WorkCandidate = work?.let { known ->
        WorkCandidate(uri = uri, title = known.title, authors = authors.map { it.name }, imageUrl = known.image)
    } ?: CreateBookRules.newWorkCandidate(draft).copy(uri = uri)
    FormPageScaffold(
        title = stringResource(R.string.create_book_work_title),
        onBack = { session.back() },
        actions = { BibliographicDataHelpButton(session::openHelp) },
        bottomBar = { CreateBookPublishBar(state = state, onPublish = session::publishEdition, onClose = onClose) },
    ) {
        state.failure?.let { failure -> item(key = "failure") { CreateBookFailureBanner(failure) } }
        item(key = "notice") { BibliographicDataNotice(onLearnMore = session::openHelp) }
        item(key = "work") {
            FormSection(header = stringResource(R.string.create_book_work_header), footer = stringResource(R.string.create_book_work_lead)) {
                WorkRow(work = candidate, showsDisclosure = false)
            }
        }
        item(key = "choice") {
            FormSection(header = stringResource(R.string.create_book_work_what_you_publish), footer = null) {
                WorkMatchChoice(
                    title = stringResource(R.string.create_book_work_one_more_edition),
                    explanation = stringResource(R.string.create_book_work_one_more_edition_help),
                    isSelected = draft.workUri != null,
                    onClick = { session.answerRecognisedWork(uri) },
                )
                WorkMatchChoice(
                    title = stringResource(R.string.create_book_work_another_book),
                    explanation = stringResource(R.string.create_book_work_another_book_help),
                    isSelected = draft.workUri == null,
                    onClick = { session.answerRecognisedWork(null) },
                )
            }
        }
    }
}

/** One of the two answers, with what it costs written under it. */
@Composable
private fun WorkMatchChoice(title: String, explanation: String, isSelected: Boolean, onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .selectable(selected = isSelected, role = Role.RadioButton, onClick = onClick)
            .padding(horizontal = Spacing.medium, vertical = Spacing.small),
        horizontalArrangement = Arrangement.spacedBy(Spacing.sMedium),
    ) {
        RadioButton(
            selected = isSelected,
            onClick = null,
            colors = RadioButtonDefaults.colors(
                selectedColor = RecitTheme.colors.foregroundTinted,
                unselectedColor = RecitTheme.colors.foregroundSecondary,
            ),
        )
        Column(verticalArrangement = Arrangement.spacedBy(Spacing.xxSmall)) {
            Text(text = title, style = RecitTheme.typography.content400Bold, color = RecitTheme.colors.foregroundDefault)
            FormFootnote(explanation)
        }
    }
}
