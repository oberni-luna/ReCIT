package studio.lunabee.nouveaurecit.ui.createbook

import android.content.ActivityNotFoundException
import android.content.Context
import android.net.Uri
import androidx.activity.compose.BackHandler
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.PhotoCamera
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.RadioButton
import androidx.compose.material3.RadioButtonDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.geometry.CornerRadius as GeometryCornerRadius
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import coil3.compose.AsyncImage
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch
import studio.lunabee.nouveaurecit.AppContainer
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.SearchResult
import studio.lunabee.nouveaurecit.data.creation.CreateBookFailure
import studio.lunabee.nouveaurecit.data.creation.NewBookAuthor
import studio.lunabee.nouveaurecit.data.creation.NewBookDraft
import studio.lunabee.nouveaurecit.data.db.AuthorEntity
import studio.lunabee.nouveaurecit.data.db.WorkEntity
import studio.lunabee.nouveaurecit.designsystem.CornerRadius
import studio.lunabee.nouveaurecit.designsystem.PrimaryButton
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.SecondaryButton
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.designsystem.WithLabel
import studio.lunabee.nouveaurecit.ui.common.LocalAppContainer
import studio.lunabee.nouveaurecit.ui.common.RecitTopBar
import java.io.File

/**
 * `CreateBookView` (feature 0020): the form that turns a scan which found nothing into a contribution
 * to inventaire.io, with its two pushed pages — the author picker and « Ce livre est connu ».
 *
 * Drawn by the camera in place of its feed, the way iOS poses a sheet on it: the flow's back stack
 * belongs to the book screen a row can open, and the two paths must not braid.
 *
 * The ISBN is shown and never edited. Publishing waits for the server, and the form cannot be left
 * while it does — a half-heard publication is the one way to make a duplicate. A failure is said here,
 * beside the button that retries, not on the shared snackbar.
 */
@Composable
fun CreateBookScreen(session: CreateBookSession, onClose: () -> Unit) {
    val state: CreateBookState by session.state.collectAsStateWithLifecycle()
    BackHandler {
        if (state.isPublishing) return@BackHandler
        if (!session.back()) onClose()
    }
    when (state.page) {
        CreateBookPage.Form -> CreateBookForm(state = state, session = session, onClose = onClose)
        CreateBookPage.Author -> AuthorPickerPage(state = state, session = session)
        CreateBookPage.Work -> WorkMatchPage(state = state, session = session)
    }
}

@Composable
private fun CreateBookForm(state: CreateBookState, session: CreateBookSession, onClose: () -> Unit) {
    val draft: NewBookDraft = state.draft
    val takeCover: () -> Unit = rememberCoverCapture(onCover = session::setCover)
    Scaffold(
        topBar = {
            RecitTopBar(
                title = stringResource(R.string.create_book_title),
                onBack = null,
                navigationIcon = {
                    IconButton(onClick = onClose, enabled = !state.isPublishing) {
                        Icon(Icons.Default.Close, contentDescription = stringResource(R.string.action_close))
                    }
                },
            )
        },
        containerColor = RecitTheme.colors.backgroundDefault,
    ) { padding ->
        Column(
            modifier = Modifier
                .padding(padding)
                .fillMaxSize()
                .imePadding()
                .verticalScroll(rememberScrollState())
                .padding(Spacing.medium),
            verticalArrangement = Arrangement.spacedBy(Spacing.medium),
        ) {
            state.failure?.let { CreateBookFailureBanner(it) }
            Row(horizontalArrangement = Arrangement.spacedBy(Spacing.medium)) {
                CreateBookCoverSlot(path = draft.coverImagePath, onClick = takeCover)
                WithLabel(label = stringResource(R.string.create_book_isbn)) {
                    Text(text = draft.isbn, style = RecitTheme.typography.content300, color = RecitTheme.colors.foregroundDefault)
                }
            }
            Column(verticalArrangement = Arrangement.spacedBy(Spacing.xSmall)) {
                // Only once the ISBN has answered: saying nothing is the honest state otherwise.
                draft.language?.displayName()?.let { language ->
                    FootnoteText(stringResource(R.string.create_book_language, language))
                }
                FootnoteText(stringResource(R.string.create_book_public_notice))
            }
            OutlinedTextField(
                value = draft.title,
                onValueChange = session::setTitle,
                label = { Text(stringResource(R.string.create_book_title_field)) },
                singleLine = true,
                textStyle = RecitTheme.typography.content300,
                keyboardOptions = KeyboardOptions(capitalization = KeyboardCapitalization.Sentences),
                modifier = Modifier.fillMaxWidth(),
            )
            CreateBookAuthorRow(draft = draft, onClick = session::openAuthorPicker)
            FootnoteText(stringResource(R.string.create_book_title_help))
            PrimaryButton(
                text = stringResource(if (state.failure?.isWorthRetrying == true) R.string.create_book_retry else R.string.create_book_publish),
                onClick = session::publish,
                enabled = draft.isPublishable,
                isLoading = state.isPublishing,
                modifier = Modifier.fillMaxWidth(),
            )
            // Only once something failed: before that, closing is closing, and a second way out is one too many.
            if (state.failure != null) {
                SecondaryButton(
                    text = stringResource(R.string.create_book_keep_draft),
                    onClick = onClose,
                    enabled = !state.isPublishing,
                    modifier = Modifier.fillMaxWidth(),
                )
            }
        }
    }
}

/**
 * The cover's way in: the camera app, writing into the cache through the FileProvider; the photos
 * instead when no camera app answers. Either way the image is reduced before it reaches the draft.
 */
@Composable
private fun rememberCoverCapture(onCover: (String) -> Unit): () -> Unit {
    val context: Context = LocalContext.current
    val scope: CoroutineScope = rememberCoroutineScope()
    var capturePath: String? by rememberSaveable { mutableStateOf(null) }
    val reduce: (Uri) -> Unit = { uri -> scope.launch { CoverPhoto.reduce(context, uri)?.let(onCover) } }
    val picker = rememberLauncherForActivityResult(ActivityResultContracts.PickVisualMedia()) { uri -> uri?.let(reduce) }
    val camera = rememberLauncherForActivityResult(ActivityResultContracts.TakePicture()) { saved ->
        val path: String? = capturePath
        if (saved && path != null) reduce(Uri.fromFile(File(path)))
    }
    return {
        val photos = PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly)
        try {
            val file: File = CoverPhoto.newCaptureFile(context)
            capturePath = file.absolutePath
            camera.launch(CoverPhoto.shareableUri(context, file))
        } catch (_: ActivityNotFoundException) {
            picker.launch(photos)
        } catch (_: SecurityException) {
            picker.launch(photos)
        }
    }
}

/** A row rather than a text field: going through the existing authors first is what avoids a twin. */
@Composable
private fun CreateBookAuthorRow(draft: NewBookDraft, onClick: () -> Unit) {
    val shape = RoundedCornerShape(CornerRadius.minimal)
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(shape)
            .border(1.dp, RecitTheme.colors.borderDefault, shape)
            .clickable(role = Role.Button, onClick = onClick)
            .padding(horizontal = Spacing.medium, vertical = Spacing.sMedium),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        // The scanner's form names one author, the first of the draft's.
        val author: NewBookAuthor? = draft.namedAuthors.firstOrNull()
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(Spacing.xxSmall)) {
            FootnoteText(stringResource(R.string.create_book_author_field))
            if (author == null) {
                Text(
                    text = stringResource(R.string.create_book_author_choose),
                    style = RecitTheme.typography.content300,
                    color = RecitTheme.colors.foregroundPlaceholder,
                )
            } else {
                Text(text = author.trimmedName, style = RecitTheme.typography.content300, color = RecitTheme.colors.foregroundDefault)
                author.description?.takeIf(String::isNotBlank)?.let { description ->
                    Text(
                        text = description,
                        style = RecitTheme.typography.footnote200,
                        color = RecitTheme.colors.foregroundSecondary,
                        maxLines = 2,
                        overflow = TextOverflow.Ellipsis,
                    )
                }
            }
        }
        Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, contentDescription = null, tint = RecitTheme.colors.foregroundSecondary)
    }
}

/** A photograph taken, or a dashed frame inviting one — dashed because the book publishes without it. */
@Composable
private fun CreateBookCoverSlot(path: String?, onClick: () -> Unit) {
    val dash: Color = RecitTheme.colors.borderDefault
    val label: String = stringResource(R.string.create_book_cover_take)
    Box(
        modifier = Modifier
            .size(width = 88.dp, height = 132.dp)
            .clip(RoundedCornerShape(CornerRadius.medium))
            .background(RecitTheme.colors.backgroundSecondary)
            .drawBehind {
                if (path == null) {
                    drawRoundRect(
                        color = dash,
                        cornerRadius = GeometryCornerRadius(CornerRadius.medium.toPx()),
                        style = Stroke(width = 1.dp.toPx(), pathEffect = PathEffect.dashPathEffect(floatArrayOf(4.dp.toPx(), 4.dp.toPx()))),
                    )
                }
            }
            .clickable(onClickLabel = label, role = Role.Button, onClick = onClick),
        contentAlignment = Alignment.Center,
    ) {
        if (path != null) {
            AsyncImage(model = File(path), contentDescription = label, contentScale = ContentScale.Crop, modifier = Modifier.fillMaxSize())
        } else {
            Column(
                modifier = Modifier.padding(Spacing.small),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(Spacing.small),
            ) {
                Icon(Icons.Default.PhotoCamera, contentDescription = null, tint = RecitTheme.colors.foregroundTinted)
                Text(
                    text = label,
                    style = RecitTheme.typography.caption200,
                    color = RecitTheme.colors.foregroundSecondary,
                    textAlign = TextAlign.Center,
                )
            }
        }
    }
}

/** Every failure says first that nothing was created: a user who fears a duplicate does not retry. */
@Composable
private fun CreateBookFailureBanner(failure: CreateBookFailure) {
    val (title: Int, body: Int) = when (failure) {
        CreateBookFailure.NeedsAccount -> R.string.create_book_failure_account_title to R.string.create_book_failure_account_body
        CreateBookFailure.Refused -> R.string.create_book_failure_refused_title to R.string.create_book_failure_refused_body
        CreateBookFailure.Network -> R.string.create_book_failure_network_title to R.string.create_book_failure_network_body
    }
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(CornerRadius.medium))
            .background(RecitTheme.colors.backgroundError)
            .padding(Spacing.sMedium)
            .semantics(mergeDescendants = true) {},
        horizontalArrangement = Arrangement.spacedBy(Spacing.small),
    ) {
        Icon(Icons.Default.Warning, contentDescription = null, tint = RecitTheme.colors.foregroundError)
        Column(verticalArrangement = Arrangement.spacedBy(Spacing.xSmall)) {
            Text(text = stringResource(title), style = RecitTheme.typography.content400Bold, color = RecitTheme.colors.foregroundError)
            Text(text = stringResource(body), style = RecitTheme.typography.footnote200, color = RecitTheme.colors.foregroundDefault)
        }
    }
}

/**
 * `AuthorPickerView`: existing authors first, each with what tells two namesakes apart, and « Créer »
 * underneath them all — a second « Ursula K. Le Guin » is the one damage a contributor of good faith
 * can do, and only someone with merge rights can undo it.
 */
@Composable
private fun AuthorPickerPage(state: CreateBookState, session: CreateBookSession) {
    val focus: FocusRequester = remember { FocusRequester() }
    LaunchedEffect(Unit) { focus.requestFocus() }
    val trimmedQuery: String = state.authorQuery.trim()
    Scaffold(
        topBar = { RecitTopBar(title = stringResource(R.string.create_book_author_field), onBack = { session.back() }) },
        containerColor = RecitTheme.colors.backgroundDefault,
    ) { padding ->
        Column(Modifier.padding(padding).fillMaxSize().imePadding()) {
            OutlinedTextField(
                value = state.authorQuery,
                onValueChange = session::searchAuthors,
                placeholder = { Text(stringResource(R.string.create_book_author_field)) },
                leadingIcon = { Icon(Icons.Default.Search, contentDescription = null) },
                singleLine = true,
                textStyle = RecitTheme.typography.content300,
                keyboardOptions = KeyboardOptions(capitalization = KeyboardCapitalization.Words, autoCorrectEnabled = false),
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = Spacing.medium, vertical = Spacing.small)
                    .focusRequester(focus),
            )
            LazyColumn(contentPadding = PaddingValues(bottom = Spacing.large)) {
                if (state.authorResults.isNotEmpty()) {
                    item {
                        PageSectionTitle(
                            text = stringResource(R.string.create_book_author_existing),
                            modifier = Modifier.padding(horizontal = Spacing.medium, vertical = Spacing.small),
                        )
                    }
                    items(state.authorResults, key = SearchResult::uri) { result ->
                        AuthorResultRow(result = result, onClick = { session.chooseAuthor(result) })
                    }
                    item {
                        FootnoteText(
                            text = stringResource(R.string.create_book_author_why_existing),
                            modifier = Modifier.padding(horizontal = Spacing.medium, vertical = Spacing.small),
                        )
                    }
                }
                if (trimmedQuery.isNotEmpty()) {
                    item {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable(role = Role.Button, onClick = session::createAuthor)
                                .padding(horizontal = Spacing.medium, vertical = Spacing.sMedium),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(Spacing.small),
                        ) {
                            Icon(Icons.Default.Add, contentDescription = null, tint = RecitTheme.colors.foregroundTinted)
                            Text(
                                text = stringResource(R.string.create_book_author_create, trimmedQuery),
                                style = RecitTheme.typography.content300,
                                color = RecitTheme.colors.foregroundTinted,
                            )
                        }
                    }
                    if (state.hasSearchedAuthors && state.authorResults.isEmpty()) {
                        item {
                            FootnoteText(
                                text = stringResource(R.string.create_book_author_no_result),
                                modifier = Modifier.padding(horizontal = Spacing.medium),
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun AuthorResultRow(result: SearchResult, onClick: () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(role = Role.Button, onClick = onClick)
            .padding(horizontal = Spacing.medium, vertical = Spacing.sMedium),
        verticalArrangement = Arrangement.spacedBy(Spacing.xxSmall),
    ) {
        Text(text = result.label, style = RecitTheme.typography.content400Bold, color = RecitTheme.colors.foregroundDefault)
        result.description?.takeIf(String::isNotBlank)?.let { description ->
            Text(
                text = description,
                style = RecitTheme.typography.footnote200,
                color = RecitTheme.colors.foregroundSecondary,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
            )
        }
    }
}

/**
 * `WorkMatchView`: « inventaire.io knows this book, but not this edition. » Shown only when the dry run
 * recognised a work. The work is read from the store, refreshed as the page opens, so the title shown
 * may differ from the one typed — that is the point of the page.
 */
@Composable
private fun WorkMatchPage(state: CreateBookState, session: CreateBookSession) {
    val container: AppContainer = LocalAppContainer.current
    val workUri: String = state.recognisedWorkUri.orEmpty()
    val work: WorkEntity? by remember(workUri) { container.entities.observeWork(workUri) }.collectAsStateWithLifecycle(null)
    val authors: List<AuthorEntity> by remember(workUri) {
        container.entities.entities.observeAuthorsOfWorks(listOf(workUri))
    }.collectAsStateWithLifecycle(emptyList())
    val draft: NewBookDraft = state.draft
    Scaffold(
        topBar = {
            RecitTopBar(
                title = stringResource(R.string.create_book_work_title),
                onBack = { if (!state.isPublishing) session.back() },
            )
        },
        containerColor = RecitTheme.colors.backgroundDefault,
    ) { padding ->
        Column(
            modifier = Modifier
                .padding(padding)
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(Spacing.medium),
            verticalArrangement = Arrangement.spacedBy(Spacing.medium),
        ) {
            PageSectionTitle(stringResource(R.string.create_book_work_header))
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(CornerRadius.medium))
                    .background(RecitTheme.colors.backgroundSecondary)
                    .padding(Spacing.medium),
                verticalArrangement = Arrangement.spacedBy(Spacing.xSmall),
            ) {
                Text(text = work?.title ?: draft.trimmedTitle, style = RecitTheme.typography.content400Bold, color = RecitTheme.colors.foregroundDefault)
                if (authors.isNotEmpty()) FootnoteText(authors.joinToString(", ") { it.name })
            }
            FootnoteText(stringResource(R.string.create_book_work_lead))
            PageSectionTitle(stringResource(R.string.create_book_work_what_you_create))
            WorkMatchChoice(
                title = stringResource(R.string.create_book_work_one_more_edition),
                explanation = stringResource(R.string.create_book_work_one_more_edition_help),
                isSelected = draft.workUri != null,
                onClick = { session.chooseWork(workUri) },
            )
            WorkMatchChoice(
                title = stringResource(R.string.create_book_work_another_book),
                explanation = stringResource(R.string.create_book_work_another_book_help),
                isSelected = draft.workUri == null,
                onClick = { session.chooseWork(null) },
            )
            PrimaryButton(
                text = stringResource(R.string.create_book_work_publish_edition),
                onClick = session::publishEdition,
                isLoading = state.isPublishing,
                modifier = Modifier.fillMaxWidth(),
            )
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
            .padding(vertical = Spacing.xSmall),
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
            FootnoteText(explanation)
        }
    }
}

@Composable
private fun PageSectionTitle(text: String, modifier: Modifier = Modifier) {
    Text(text = text, style = RecitTheme.typography.action200, color = RecitTheme.colors.foregroundSecondary, modifier = modifier)
}

@Composable
private fun FootnoteText(text: String, modifier: Modifier = Modifier) {
    Text(text = text, style = RecitTheme.typography.footnote200, color = RecitTheme.colors.foregroundSecondary, modifier = modifier)
}
