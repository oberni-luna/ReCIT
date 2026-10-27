package studio.lunabee.nouveaurecit.ui.editedition

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.automirrored.outlined.HelpOutline
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.UnfoldMore
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.SwipeToDismissBox
import androidx.compose.material3.SwipeToDismissBoxState
import androidx.compose.material3.SwipeToDismissBoxValue
import androidx.compose.material3.Text
import androidx.compose.material3.rememberSwipeToDismissBoxState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.CustomAccessibilityAction
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.customActions
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import coil3.compose.AsyncImage
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.launch
import studio.lunabee.nouveaurecit.AppContainer
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.creation.WorkCandidate
import studio.lunabee.nouveaurecit.designsystem.CornerRadius
import studio.lunabee.nouveaurecit.designsystem.PrimaryButton
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.SectionHeader
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.designsystem.WithLabel
import studio.lunabee.nouveaurecit.ui.common.LocalAppContainer

/*
 * The pieces every page of the edition's form is made of — « Modifier l'édition » and the scanner's
 * « Nouvelle édition » alike: an inset-grouped section with its header and footer, the rows of the
 * Figma file's `Form / *` components, the swipe that takes a value away, the failure banner, the notice
 * and its « ? ».
 */

/**
 * A `Section` of an iOS `Form`: its header, its rows on one rounded card of the cells' colour, and the
 * sentence under it. Rows are separated by [FormDivider], placed by the caller.
 */
@Composable
fun FormSection(
    header: String?,
    footer: String?,
    modifier: Modifier = Modifier,
    content: @Composable ColumnScope.() -> Unit,
) {
    Column(modifier.fillMaxWidth()) {
        if (header != null) SectionHeader(title = header)
        Column(
            Modifier
                .padding(horizontal = Spacing.medium)
                .fillMaxWidth()
                .clip(RoundedCornerShape(CornerRadius.rounded))
                .background(RecitTheme.colors.backgroundGroupedCell),
            content = content,
        )
        if (footer != null) FormFootnote(text = footer, modifier = Modifier.padding(horizontal = Spacing.large, vertical = Spacing.small))
    }
}

/** The line between two rows of a [FormSection], inset like the system's. */
@Composable
fun FormDivider() {
    HorizontalDivider(modifier = Modifier.padding(start = Spacing.medium), color = RecitTheme.colors.borderDefault)
}

/** A sentence under a section (`CreateBookSectionFooter`): footnote, secondary — or error, when it says what is wrong. */
@Composable
fun FormFootnote(text: String, modifier: Modifier = Modifier, color: Color = RecitTheme.colors.foregroundSecondary) {
    Text(text = text, style = RecitTheme.typography.footnote200, color = color, modifier = modifier)
}

/**
 * A field as the form's rows draw it (`TextField` + `withLabel`): its name above, the text below, no
 * outline — on a card, an outlined field would be a box in a box.
 */
@Composable
fun FormTextRow(
    label: String,
    value: String,
    onValueChange: (String) -> Unit,
    modifier: Modifier = Modifier,
    placeholder: String = label,
    enabled: Boolean = true,
    singleLine: Boolean = true,
    keyboardOptions: KeyboardOptions = KeyboardOptions.Default,
) {
    val color: Color = if (enabled) RecitTheme.colors.foregroundDefault else RecitTheme.colors.foregroundSecondary
    WithLabel(label = label, modifier = modifier.fillMaxWidth().padding(horizontal = Spacing.medium, vertical = Spacing.sMedium)) {
        BasicTextField(
            value = value,
            onValueChange = onValueChange,
            enabled = enabled,
            singleLine = singleLine,
            textStyle = RecitTheme.typography.content300.copy(color = color),
            cursorBrush = SolidColor(RecitTheme.colors.foregroundTinted),
            keyboardOptions = keyboardOptions,
            modifier = Modifier.fillMaxWidth(),
            decorationBox = { field ->
                Box {
                    if (value.isEmpty()) {
                        Text(text = placeholder, style = RecitTheme.typography.content300, color = RecitTheme.colors.foregroundPlaceholder)
                    }
                    field()
                }
            },
        )
    }
}

/** What touching an [EditionPropertyRow] does, drawn at its trailing edge. */
enum class PropertyRowTrailing { None, Chevron, Menu }

/**
 * `EditionPropertyRow`: a property's name above, its value — or an invitation in the placeholder colour —
 * below. Chevron pushes a choice, Menu opens a menu (the format), None is a value shown.
 */
@Composable
fun EditionPropertyRow(
    label: String,
    value: String?,
    placeholder: String,
    modifier: Modifier = Modifier,
    trailing: PropertyRowTrailing = PropertyRowTrailing.Chevron,
    onClick: (() -> Unit)? = null,
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .then(if (onClick != null) Modifier.clickable(role = Role.Button, onClick = onClick) else Modifier)
            .padding(horizontal = Spacing.medium, vertical = Spacing.sMedium),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(Spacing.small),
    ) {
        WithLabel(label = label, modifier = Modifier.weight(1f)) {
            Text(
                text = value ?: placeholder,
                style = RecitTheme.typography.content300,
                color = if (value != null) RecitTheme.colors.foregroundDefault else RecitTheme.colors.foregroundPlaceholder,
            )
        }
        when (trailing) {
            PropertyRowTrailing.None -> Unit
            PropertyRowTrailing.Chevron ->
                Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, contentDescription = null, tint = RecitTheme.colors.foregroundSecondary)
            PropertyRowTrailing.Menu -> Icon(Icons.Default.UnfoldMore, contentDescription = null, tint = RecitTheme.colors.foregroundSecondary)
        }
    }
}

/** `EditEditionActionRow`: a « + » and a tinted label — « Ajouter une œuvre », « Ajouter un identifiant ». */
@Composable
fun FormActionRow(title: String, onClick: () -> Unit, modifier: Modifier = Modifier, enabled: Boolean = true) {
    val color: Color = if (enabled) RecitTheme.colors.foregroundTinted else RecitTheme.colors.foregroundDisable
    Row(
        modifier = modifier
            .fillMaxWidth()
            .heightIn(min = MinRowHeight)
            .clickable(enabled = enabled, role = Role.Button, onClick = onClick)
            .padding(horizontal = Spacing.medium, vertical = Spacing.sMedium),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(Spacing.small),
    ) {
        Icon(Icons.Default.Add, contentDescription = null, tint = color)
        Text(text = title, style = RecitTheme.typography.content300, color = color)
    }
}

/**
 * `.swipeActions(edge: .trailing)` with one destructive button: swiping from the end reveals [label] in
 * the error colours and runs [onRemove] — a change to the draft, nothing sent. TalkBack gets the same
 * action, since a swipe is out of its reach.
 *
 * Callers key each row by its value (`key(id) { … }`), so the swipe state of a row taken away does not
 * pass to the one that slides up in its place.
 */
@Composable
fun SwipeToRemoveRow(
    label: String,
    onRemove: () -> Unit,
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit,
) {
    val state: SwipeToDismissBoxState = rememberSwipeToDismissBoxState()
    val scope: CoroutineScope = rememberCoroutineScope()
    LaunchedEffect(state.currentValue) {
        if (state.currentValue == SwipeToDismissBoxValue.EndToStart) {
            onRemove()
            scope.launch { state.reset() }
        }
    }
    SwipeToDismissBox(
        state = state,
        modifier = modifier.semantics {
            customActions = listOf(
                CustomAccessibilityAction(label) {
                    onRemove()
                    true
                },
            )
        },
        enableDismissFromStartToEnd = false,
        backgroundContent = {
            Row(
                modifier = Modifier
                    .fillMaxSize()
                    .background(RecitTheme.colors.backgroundError)
                    .padding(horizontal = Spacing.medium),
                horizontalArrangement = Arrangement.End,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(label, style = RecitTheme.typography.action300, color = RecitTheme.colors.foregroundError)
            }
        },
    ) {
        Box(Modifier.background(RecitTheme.colors.backgroundGroupedCell)) { content() }
    }
}

/**
 * An entity a property names, or an author of a work (`EditWorkAuthorRow`): the name, and under it what
 * tells it apart — the search's description, or that it will be created on saving.
 */
@Composable
fun EntityValueRow(label: String, detail: String?, isNew: Boolean, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .heightIn(min = MinRowHeight)
            .padding(horizontal = Spacing.medium, vertical = Spacing.sMedium)
            .semantics(mergeDescendants = true) {},
        verticalArrangement = Arrangement.spacedBy(Spacing.xxSmall),
    ) {
        Text(text = label, style = RecitTheme.typography.content300, color = RecitTheme.colors.foregroundDefault)
        val under: String? = if (isNew) stringResource(R.string.edit_edition_work_new_author) else detail?.takeIf(String::isNotBlank)
        if (under != null) {
            Text(
                text = under,
                style = RecitTheme.typography.footnote200,
                color = RecitTheme.colors.foregroundSecondary,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
            )
        }
    }
}

/**
 * `WorkRow`: one work as the reader recognises it — the whole cover at 2:3, the title, who wrote it and
 * when. The chevron when the row leads somewhere.
 */
@Composable
fun WorkRow(work: WorkCandidate, modifier: Modifier = Modifier, showsDisclosure: Boolean = true, onClick: (() -> Unit)? = null) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .then(if (onClick != null) Modifier.clickable(role = Role.Button, onClick = onClick) else Modifier)
            .padding(horizontal = Spacing.medium, vertical = Spacing.small)
            .semantics(mergeDescendants = true) {},
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(Spacing.sMedium),
    ) {
        Box(
            Modifier
                .size(width = WorkCoverWidth, height = WorkCoverHeight)
                .clip(RoundedCornerShape(BookCornerRadius))
                .background(RecitTheme.colors.backgroundSecondary),
        ) {
            if (work.imageUrl != null) {
                AsyncImage(model = work.imageUrl, contentDescription = null, contentScale = ContentScale.Crop, modifier = Modifier.fillMaxSize())
            }
        }
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(Spacing.xxSmall)) {
            Text(text = work.title, style = RecitTheme.typography.content400Bold, color = RecitTheme.colors.foregroundDefault)
            work.detail?.takeIf(String::isNotBlank)?.let { detail ->
                Text(
                    text = detail,
                    style = RecitTheme.typography.footnote200,
                    color = RecitTheme.colors.foregroundSecondary,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                )
            }
        }
        if (showsDisclosure) {
            Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, contentDescription = null, tint = RecitTheme.colors.foregroundPlaceholder)
        }
    }
}

/**
 * `CreateBookFailureBanner`: what went wrong, in the reader's terms, at the head of the form that sent —
 * whose words say what a retry does.
 */
@Composable
fun FormFailureBanner(title: String, body: String, modifier: Modifier = Modifier) {
    Row(
        modifier = modifier
            .padding(horizontal = Spacing.medium)
            .fillMaxWidth()
            .clip(RoundedCornerShape(CornerRadius.medium))
            .background(RecitTheme.colors.backgroundError)
            .padding(Spacing.sMedium)
            .semantics(mergeDescendants = true) {},
        horizontalArrangement = Arrangement.spacedBy(Spacing.small),
    ) {
        Icon(Icons.Default.Warning, contentDescription = null, tint = RecitTheme.colors.foregroundError)
        Column(verticalArrangement = Arrangement.spacedBy(Spacing.xSmall)) {
            Text(text = title, style = RecitTheme.typography.content400Bold, color = RecitTheme.colors.foregroundError)
            Text(text = body, style = RecitTheme.typography.footnote200, color = RecitTheme.colors.foregroundDefault)
        }
    }
}

/**
 * `BibliographicDataNotice`: where works, editions and authors come from, and that what is typed becomes
 * public. Shown until put away, then put away everywhere and for good — the « ? » opens the whole of it
 * whenever it is wanted again. The key is iOS's, so the two apps speak of the same notice.
 */
@Composable
fun BibliographicDataNotice(onLearnMore: () -> Unit, modifier: Modifier = Modifier) {
    val container: AppContainer = LocalAppContainer.current
    val dismissed: Flow<Boolean> = remember(container) { container.preferences.observeBoolean(NOTICE_DISMISSED_KEY) }
    // Hidden until the preference has answered: a notice that flashes up and vanishes is worse than none.
    val isDismissed: Boolean by dismissed.collectAsStateWithLifecycle(initialValue = true)
    if (isDismissed) return
    val scope: CoroutineScope = rememberCoroutineScope()
    Row(
        modifier = modifier
            .padding(horizontal = Spacing.medium)
            .fillMaxWidth()
            .clip(RoundedCornerShape(CornerRadius.medium))
            .background(RecitTheme.colors.backgroundTinted)
            .padding(start = Spacing.medium, top = Spacing.sMedium, bottom = Spacing.sMedium),
        horizontalArrangement = Arrangement.spacedBy(Spacing.sMedium),
    ) {
        Icon(Icons.AutoMirrored.Outlined.HelpOutline, contentDescription = null, tint = RecitTheme.colors.foregroundTinted)
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(Spacing.xSmall)) {
            Text(stringResource(R.string.create_book_notice_title), style = RecitTheme.typography.content300, color = RecitTheme.colors.foregroundDefault)
            Text(stringResource(R.string.create_book_notice_body), style = RecitTheme.typography.footnote200, color = RecitTheme.colors.foregroundDefault)
            Text(
                text = stringResource(R.string.create_book_notice_learn_more),
                style = RecitTheme.typography.footnote200Bold,
                color = RecitTheme.colors.foregroundTinted,
                modifier = Modifier.clickable(role = Role.Button, onClick = onLearnMore),
            )
        }
        IconButton(onClick = { scope.launch { container.preferences.setBoolean(NOTICE_DISMISSED_KEY, true) } }) {
            Icon(Icons.Default.Close, contentDescription = stringResource(R.string.action_close), tint = RecitTheme.colors.foregroundSecondary)
        }
    }
}

/** `BibliographicDataHelpButton`: the « ? » at the trailing end of the bar, which opens the help. */
@Composable
fun BibliographicDataHelpButton(onClick: () -> Unit) {
    IconButton(onClick = onClick) {
        Icon(Icons.AutoMirrored.Outlined.HelpOutline, contentDescription = stringResource(R.string.create_book_notice_title))
    }
}

/**
 * `EditEditionSaveBar`: the primary action pinned at the foot of the screen — the form is long, and
 * saving it must not mean scrolling to its end.
 */
@Composable
fun FormActionBar(text: String, onClick: () -> Unit, enabled: Boolean, isLoading: Boolean, modifier: Modifier = Modifier) {
    Box(
        modifier
            .fillMaxWidth()
            .background(RecitTheme.colors.backgroundGrouped)
            .navigationBarsPadding()
            .padding(horizontal = Spacing.medium, vertical = Spacing.small),
    ) {
        PrimaryButton(text = text, onClick = onClick, enabled = enabled, isLoading = isLoading)
    }
}

/** `@AppStorage("createBook.bibliographicNotice.dismissed")`. */
private const val NOTICE_DISMISSED_KEY: String = "createBook.bibliographicNotice.dismissed"

/** A row's touch target, as Material asks. */
private val MinRowHeight: Dp = 48.dp

/** A cover at 36 × 54: a book's 2:3, which recognising the one in hand takes. */
private val WorkCoverWidth: Dp = 36.dp
private val WorkCoverHeight: Dp = 54.dp

/** A book's corner, as the shelves draw it: off the radius scale on purpose. */
private val BookCornerRadius: Dp = 2.dp
