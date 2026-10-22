package studio.lunabee.nouveaurecit.ui.sort

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.sorting.SortDraftNameRule
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing

/**
 * `ShelfFormView(draft:)`: a name and nothing else. Nothing is written — the étagère becomes a draft
 * of the session, created on « Enregistrer ». A name already on screen is refused as it is typed, so a
 * refused name never leaves a book filed into a draft that does not exist.
 */
@Composable
fun SortNewShelfDialog(nameRule: SortDraftNameRule, onCreate: (String) -> Unit, onDismiss: () -> Unit) {
    var name: String by rememberSaveable { mutableStateOf("") }
    val refusal: SortDraftNameRule.Refusal? = nameRule.refusal(name)
    val focusRequester: FocusRequester = remember { FocusRequester() }
    val submit: () -> Unit = {
        if (refusal == null) onCreate(name.trim())
    }
    LaunchedEffect(Unit) { runCatching { focusRequester.requestFocus() } }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(stringResource(R.string.shelf_form_title_new)) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(Spacing.small)) {
                OutlinedTextField(
                    value = name,
                    onValueChange = { name = it },
                    label = { Text(stringResource(R.string.shelf_form_name)) },
                    singleLine = true,
                    isError = refusal is SortDraftNameRule.Refusal.AlreadyUsed,
                    keyboardOptions = KeyboardOptions(capitalization = KeyboardCapitalization.Sentences, imeAction = ImeAction.Done),
                    keyboardActions = KeyboardActions(onDone = { submit() }),
                    modifier = Modifier.fillMaxWidth().focusRequester(focusRequester),
                )
                if (refusal is SortDraftNameRule.Refusal.AlreadyUsed) {
                    Text(
                        text = stringResource(R.string.sort_create_name_taken, refusal.name),
                        style = RecitTheme.typography.footnote200,
                        color = RecitTheme.colors.foregroundError,
                    )
                }
            }
        },
        confirmButton = {
            TextButton(onClick = submit, enabled = refusal == null) { Text(stringResource(R.string.shelf_form_create)) }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text(stringResource(R.string.shelf_form_close)) }
        },
    )
}
