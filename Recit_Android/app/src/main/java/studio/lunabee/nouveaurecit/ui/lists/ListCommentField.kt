package studio.lunabee.nouveaurecit.ui.lists

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.State
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusManager
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.OptimisticRunner
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing

/**
 * `ListCommentRow`: « Mon commentaire » on the element facing the reader, written when it is left — the
 * field losing focus, the keyboard's « OK », or the element swiped away. A draft being typed keeps its own
 * text; otherwise the field follows the store, so a sync or a reverted write shows. Disabled for an element
 * the server has not created yet: there is no id to write on.
 */
@Composable
internal fun ListCommentField(
    row: ListElementRowModel,
    isAuthor: Boolean,
    onFocusChange: (Boolean) -> Unit,
    onSave: (String) -> Unit,
    modifier: Modifier = Modifier,
) {
    var draft: String by remember(row.uri) { mutableStateOf(row.comment) }
    var isFocused: Boolean by remember { mutableStateOf(false) }
    val focusManager: FocusManager = LocalFocusManager.current
    val latestDraft: State<String> = rememberUpdatedState(draft)
    val latestOnSave: State<(String) -> Unit> = rememberUpdatedState(onSave)

    LaunchedEffect(row.comment) {
        if (!isFocused) draft = row.comment
    }
    // Swiped away mid-sentence: what was typed is still written.
    DisposableEffect(row.uri) {
        onDispose { latestOnSave.value(latestDraft.value) }
    }

    Column(modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(Spacing.xSmall)) {
        Text(stringResource(R.string.list_detail_comment_label), style = RecitTheme.typography.footnote200, color = RecitTheme.colors.foregroundSecondary)
        BasicTextField(
            value = draft,
            onValueChange = { draft = it },
            enabled = !OptimisticRunner.isOptimistic(row.elementId),
            textStyle = RecitTheme.typography.content300.copy(color = RecitTheme.colors.foregroundDefault),
            cursorBrush = SolidColor(RecitTheme.colors.foregroundTinted),
            keyboardOptions = KeyboardOptions(capitalization = KeyboardCapitalization.Sentences, imeAction = ImeAction.Done),
            keyboardActions = KeyboardActions(onDone = { focusManager.clearFocus() }),
            modifier = Modifier
                .fillMaxWidth()
                .onFocusChanged { state ->
                    if (isFocused && !state.isFocused) onSave(draft)
                    if (isFocused != state.isFocused) onFocusChange(state.isFocused)
                    isFocused = state.isFocused
                },
            decorationBox = { field ->
                Box {
                    if (draft.isEmpty()) {
                        Text(
                            stringResource(if (isAuthor) R.string.list_detail_comment_placeholder_author else R.string.list_detail_comment_placeholder_work),
                            style = RecitTheme.typography.content300,
                            color = RecitTheme.colors.foregroundPlaceholder,
                        )
                    }
                    field()
                }
            },
        )
    }
}
