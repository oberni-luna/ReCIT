package studio.lunabee.nouveaurecit.ui.editedition

import androidx.annotation.StringRes
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.outlined.Link
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.platform.UriHandler
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import kotlinx.coroutines.flow.Flow
import studio.lunabee.nouveaurecit.AppContainer
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.creation.EntitySearchHit
import studio.lunabee.nouveaurecit.data.creation.NewBookAuthor
import studio.lunabee.nouveaurecit.data.creation.WorkCandidate
import studio.lunabee.nouveaurecit.data.creation.WorkEdit
import studio.lunabee.nouveaurecit.data.db.UserEntity
import studio.lunabee.nouveaurecit.designsystem.EmptyState
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.SectionHeader
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.ui.common.LocalAppContainer

/*
 * The pages about works: the search for the work an edition is of, « Modifier l'œuvre » and its author
 * search — and the help the « ? » of every one of them opens.
 */

/**
 * `WorkSearchView`: the works inventaire.io has, found by title or by author, each with who wrote it and
 * when; creating one comes last. [emptyTitle] and [emptyMessage] are what the page says before anything
 * is typed — « Modifier l'édition » and the scanner's « Nouveau livre » each have their own. The scanner's
 * opens on it, and [closes]: its way back is a cross that closes the whole creation.
 */
@Composable
fun WorkSearchPage(
    title: String,
    emptyTitle: String,
    emptyMessage: String,
    search: SearchState<WorkCandidate>,
    onQueryChange: (String) -> Unit,
    onChoose: (WorkCandidate) -> Unit,
    onCreate: (String) -> Unit,
    onHelp: () -> Unit,
    onBack: () -> Unit,
    closes: Boolean = false,
) {
    val query: String = search.trimmedQuery
    val close: (@Composable () -> Unit)? = if (closes) {
        {
            IconButton(onClick = onBack) {
                Icon(Icons.Default.Close, contentDescription = stringResource(R.string.action_close))
            }
        }
    } else {
        null
    }
    FormPageScaffold(title = title, onBack = onBack, actions = { BibliographicDataHelpButton(onHelp) }, navigationIcon = close) {
        item(key = "field") { PickerSearchField(search.query, onQueryChange, stringResource(R.string.create_book_search_prompt)) }
        item(key = "notice") { BibliographicDataNotice(onLearnMore = onHelp, modifier = Modifier.padding(vertical = Spacing.small)) }
        when {
            query.isEmpty() -> item(key = "empty") {
                EmptyState(title = emptyTitle, message = emptyMessage, icon = Icons.Default.Search, modifier = Modifier.padding(vertical = Spacing.xLarge))
            }
            search.results.isNotEmpty() -> {
                item(key = "results") {
                    FormSection(header = stringResource(R.string.create_book_search_results), footer = stringResource(R.string.create_book_search_why_existing)) {
                        search.results.forEachIndexed { index, work ->
                            key(work.uri) {
                                if (index > 0) FormDivider()
                                WorkRow(work = work, onClick = { onChoose(work) })
                            }
                        }
                    }
                }
                item(key = "none-match") {
                    FormSection(header = null, footer = null, modifier = Modifier.padding(top = Spacing.medium)) {
                        FormActionRow(title = stringResource(R.string.create_book_search_none_match), onClick = { onCreate(query) })
                    }
                }
            }
            else -> item(key = "create") {
                FormSection(
                    header = null,
                    footer = if (search.hasSearched) stringResource(R.string.create_book_search_no_result) else null,
                    modifier = Modifier.padding(top = Spacing.medium),
                ) {
                    FormActionRow(title = stringResource(R.string.create_book_search_create, query), onClick = { onCreate(query) })
                }
            }
        }
    }
}

/**
 * `EditWorkView`: one work of the edition — its title and its authors, the only place they change: an
 * author belongs to the work, for every edition of it. Nothing is sent from here; what changes goes with
 * « Enregistrer ». A Wikidata work is shown and not changed.
 *
 * The scanner's « Nouvelle œuvre » is this page over the work its draft describes, with its own [footer]:
 * there, the work is published with the edition.
 */
@Composable
fun EditWorkPage(
    work: WorkEdit,
    onTitle: (String) -> Unit,
    onRemoveAuthor: (index: Int) -> Unit,
    onAddAuthor: () -> Unit,
    onHelp: () -> Unit,
    onBack: () -> Unit,
    @StringRes footer: Int = when (EditionFormRules.workFooter(work)) {
        EditionFormRules.WorkFooter.Wikidata -> R.string.edit_work_wikidata_help
        EditionFormRules.WorkFooter.New -> R.string.edit_work_new_help
        EditionFormRules.WorkFooter.Default -> R.string.edit_work_help
    },
) {
    FormPageScaffold(
        title = stringResource(if (work.isNew) R.string.create_book_new_work_title else R.string.edit_work_title),
        onBack = onBack,
        actions = { BibliographicDataHelpButton(onHelp) },
    ) {
        item(key = "work") {
            FormSection(header = stringResource(R.string.edit_work_header), footer = stringResource(footer)) {
                FormTextRow(
                    label = stringResource(R.string.create_book_new_work_title_field),
                    value = work.title,
                    onValueChange = onTitle,
                    enabled = work.isEditable,
                    keyboardOptions = KeyboardOptions(capitalization = KeyboardCapitalization.Sentences),
                )
                val remove: String = stringResource(R.string.edit_edition_remove)
                work.authors.forEachIndexed { index, author ->
                    key(author.id) {
                        FormDivider()
                        if (work.isEditable) {
                            SwipeToRemoveRow(label = remove, onRemove = { onRemoveAuthor(index) }) { AuthorRow(author) }
                        } else {
                            AuthorRow(author)
                        }
                    }
                }
                if (work.isEditable) {
                    FormDivider()
                    FormActionRow(
                        title = stringResource(if (work.authors.isEmpty()) R.string.edit_edition_work_add_author else R.string.edit_work_add_other_author),
                        onClick = onAddAuthor,
                    )
                }
            }
        }
    }
}

@Composable
private fun AuthorRow(author: NewBookAuthor) {
    EntityValueRow(label = author.trimmedName, detail = author.description, isNew = author.uri == null)
}

/**
 * `AuthorPickerView`: the author to add to a work — existing ones first, each with what tells two
 * namesakes apart, « Créer » under them all. It answers one author and knows nothing of the work.
 */
@Composable
fun AuthorSearchPage(
    search: SearchState<EntitySearchHit>,
    onQueryChange: (String) -> Unit,
    onChoose: (NewBookAuthor) -> Unit,
    onBack: () -> Unit,
    actions: @Composable RowScope.() -> Unit = {},
) {
    val query: String = search.trimmedQuery
    EntitySearchPage(
        title = stringResource(R.string.create_book_author_field),
        placeholder = stringResource(R.string.create_book_author_field),
        search = search,
        onQueryChange = onQueryChange,
        existingHeader = stringResource(R.string.create_book_author_existing),
        existingFooter = stringResource(R.string.create_book_author_why_existing),
        createLabel = if (query.isNotEmpty()) stringResource(R.string.create_book_author_create, query) else null,
        canCreate = true,
        createFooter = if (search.hasSearched && search.results.isEmpty()) stringResource(R.string.create_book_author_no_result) else null,
        onChoose = { hit -> onChoose(NewBookAuthor(name = hit.label, uri = hit.uri, description = hit.description)) },
        onCreate = { onChoose(NewBookAuthor(name = query)) },
        onBack = onBack,
        actions = actions,
    )
}

/**
 * `BibliographicDataHelpView`: « Données bibliographiques », in full — what they are, where they come
 * from, what publishing here means — and where to go further. « Voir mes contributions » needs to know
 * who is asking, and is left out when that is not known.
 */
@Composable
fun BibliographicDataHelpPage(onBack: () -> Unit) {
    val container: AppContainer = LocalAppContainer.current
    val myUser: Flow<UserEntity?> = remember(container) { container.users.myUser }
    val me: UserEntity? by myUser.collectAsStateWithLifecycle(initialValue = null)
    val uriHandler: UriHandler = LocalUriHandler.current
    val paragraphs: List<Pair<Int, Int>> = listOf(
        R.string.create_book_help_what to R.string.create_book_help_what_body,
        R.string.create_book_help_from to R.string.create_book_help_from_body,
        R.string.create_book_help_publish to R.string.create_book_help_publish_body,
    )
    val links: List<Pair<Int, String>> = listOfNotNull(
        R.string.create_book_help_wiki to BibliographicDataLinks.WIKI,
        R.string.create_book_help_chat to BibliographicDataLinks.CHAT,
        me?.username?.let(BibliographicDataLinks::contributions)?.let { R.string.create_book_help_contributions to it },
    )
    FormPageScaffold(title = stringResource(R.string.create_book_notice_title), onBack = onBack) {
        paragraphs.forEach { (header, body) ->
            item(key = "paragraph:$header") {
                // Reading, not a form: the text sits in the column rather than on a card.
                Column(verticalArrangement = Arrangement.spacedBy(Spacing.xSmall)) {
                    SectionHeader(title = stringResource(header))
                    Text(
                        text = stringResource(body),
                        style = RecitTheme.typography.content300,
                        color = RecitTheme.colors.foregroundDefault,
                        modifier = Modifier.padding(horizontal = Spacing.medium),
                    )
                }
            }
        }
        item(key = "further") {
            FormSection(header = stringResource(R.string.create_book_help_further), footer = null) {
                links.forEachIndexed { index, (title, url) ->
                    if (index > 0) FormDivider()
                    LinkRow(title = stringResource(title), onClick = { uriHandler.openUri(url) })
                }
            }
        }
    }
}

/** One way further, as a tinted link row. */
@Composable
private fun LinkRow(title: String, onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(role = Role.Button, onClick = onClick)
            .padding(horizontal = Spacing.medium, vertical = Spacing.sMedium),
        horizontalArrangement = Arrangement.spacedBy(Spacing.small),
    ) {
        Icon(Icons.Outlined.Link, contentDescription = null, tint = RecitTheme.colors.foregroundTinted)
        Text(title, style = RecitTheme.typography.content300, color = RecitTheme.colors.foregroundTinted)
    }
}
