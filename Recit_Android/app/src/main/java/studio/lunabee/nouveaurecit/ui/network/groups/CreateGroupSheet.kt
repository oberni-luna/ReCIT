package studio.lunabee.nouveaurecit.ui.network.groups

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.SheetState
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.async
import kotlinx.coroutines.launch
import studio.lunabee.nouveaurecit.AppContainer
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.groups.GroupNameRule
import studio.lunabee.nouveaurecit.data.groups.ReaderGroup
import studio.lunabee.nouveaurecit.designsystem.FormTextField
import studio.lunabee.nouveaurecit.designsystem.PrimaryButton
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.SheetHeader
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.ui.common.LocalAppContainer

/**
 * `CreateGroupView`: starting a group, as a sheet like the étagère and list forms.
 *
 * The only write of the Groupes segment that waits for the server (see `GroupRepository.createGroup`):
 * the button spins, a refusal is said under it, and a success closes the sheet onto the new group's
 * screen. The request runs in the application scope, so closing the sheet mid-request stops the
 * waiting, not the write.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CreateGroupSheet(onDismiss: () -> Unit, onCreated: (String) -> Unit) {
    val container: AppContainer = LocalAppContainer.current
    val scope: CoroutineScope = rememberCoroutineScope()
    val sheetState: SheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)

    var name: String by rememberSaveable { mutableStateOf("") }
    var description: String by rememberSaveable { mutableStateOf("") }
    // The server's own defaults: a group can be found, and lets nobody in unasked.
    var searchable: Boolean by rememberSaveable { mutableStateOf(true) }
    var open: Boolean by rememberSaveable { mutableStateOf(false) }
    var isSubmitting: Boolean by remember { mutableStateOf(false) }
    var failed: Boolean by rememberSaveable { mutableStateOf(false) }

    fun create() {
        if (isSubmitting) return
        isSubmitting = true
        scope.launch {
            val result: Result<ReaderGroup> = runCatching {
                container.applicationScope.async { container.groups.createGroup(name, description, searchable, open) }.await()
            }
            isSubmitting = false
            result
                .onSuccess { group ->
                    onDismiss()
                    onCreated(group.id)
                }
                .onFailure { failed = true }
        }
    }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState,
        containerColor = RecitTheme.colors.backgroundRaised,
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .verticalScroll(rememberScrollState())
                .imePadding()
                .padding(horizontal = Spacing.medium)
                .padding(bottom = Spacing.large),
            verticalArrangement = Arrangement.spacedBy(Spacing.medium),
        ) {
            SheetHeader(
                title = stringResource(R.string.groups_form_new),
                closeLabel = stringResource(R.string.action_close),
                onClose = onDismiss,
            )
            GroupTextFields(
                name = name,
                onNameChange = { name = it },
                description = description,
                onDescriptionChange = { description = it },
            )
            GroupAccessSection(
                searchable = searchable,
                onSearchableChange = { searchable = it },
                open = open,
                onOpenChange = { open = it },
            )
            PrimaryButton(
                text = stringResource(R.string.groups_form_create),
                onClick = ::create,
                enabled = GroupNameRule.accepts(name),
                isLoading = isSubmitting,
            )
            GroupNote(stringResource(if (failed) R.string.groups_form_create_failed else R.string.groups_form_create_note))
        }
    }
}

/** The name and the description, and the sentence under the name when it is too long. */
@Composable
internal fun GroupTextFields(
    name: String,
    onNameChange: (String) -> Unit,
    description: String,
    onDescriptionChange: (String) -> Unit,
) {
    Column(verticalArrangement = Arrangement.spacedBy(Spacing.small)) {
        FormTextField(
            value = name,
            onValueChange = onNameChange,
            label = stringResource(R.string.groups_form_name),
        )
        if (GroupNameRule.isTooLong(name)) {
            Text(
                text = stringResource(R.string.groups_form_name_too_long, GroupNameRule.MAXIMUM_LENGTH),
                style = RecitTheme.typography.footnote200,
                color = RecitTheme.colors.foregroundError,
            )
        }
        FormTextField(
            value = description,
            onValueChange = onDescriptionChange,
            label = stringResource(R.string.groups_form_description),
            singleLine = false,
            minLines = 2,
            maxLines = 5,
        )
    }
}
