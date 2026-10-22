package studio.lunabee.nouveaurecit.ui.inventory

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SheetState
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import studio.lunabee.nouveaurecit.AppContainer
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.db.ShelfEntity
import studio.lunabee.nouveaurecit.data.db.UserEntity
import studio.lunabee.nouveaurecit.designsystem.ConfirmDialog
import studio.lunabee.nouveaurecit.designsystem.DestructiveTextButton
import studio.lunabee.nouveaurecit.designsystem.FormTextField
import studio.lunabee.nouveaurecit.designsystem.PrimaryButton
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.SheetHeader
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.designsystem.WithLabel
import studio.lunabee.nouveaurecit.ui.common.LocalAppContainer
import studio.lunabee.nouveaurecit.ui.common.LocalMessenger
import studio.lunabee.nouveaurecit.ui.common.Messenger

/**
 * `ShelfFormView`, as a sheet: create (`shelfId == null`), edit (`shelfId` set), or create and file
 * one copy in it (`fileItemId` set). [onDeleted] runs after the shelf was deleted from the edit form.
 *
 * Every write is optimistic (`ShelfRepository`): it lands in the store at once, so the sheet closes
 * straight away and a server refusal surfaces as the app's error snackbar. Writes run in the
 * application scope, so closing the sheet never cancels them.
 */
@Composable
fun ShelfFormSheet(
    shelfId: String?,
    fileItemId: String?,
    onDismiss: () -> Unit,
    onDeleted: () -> Unit = {},
) {
    val container: AppContainer = LocalAppContainer.current
    val messenger: Messenger = LocalMessenger.current
    val sheetState: SheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    val sheetScope: CoroutineScope = rememberCoroutineScope()
    val isEditing: Boolean = shelfId != null

    var name: String by rememberSaveable { mutableStateOf("") }
    var description: String by rememberSaveable { mutableStateOf("") }
    var visibility: ShelfVisibility by rememberSaveable { mutableStateOf(ShelfVisibility.Private) }
    var isFilled: Boolean by rememberSaveable { mutableStateOf(!isEditing) }
    var isConfirmingDelete: Boolean by rememberSaveable { mutableStateOf(false) }

    LaunchedEffect(shelfId) {
        if (shelfId == null || isFilled) return@LaunchedEffect
        val shelf: ShelfEntity = container.shelves.observeShelf(shelfId).first()?.shelf ?: return@LaunchedEffect
        name = shelf.name
        description = shelf.description
        visibility = ShelfVisibility.from(shelf.visibility)
        isFilled = true
    }

    val canSubmit: Boolean = name.isNotBlank() && isFilled
    val close: () -> Unit = {
        sheetScope.launch { sheetState.hide() }.invokeOnCompletion { onDismiss() }
    }
    val addedTo: String = stringResource(R.string.shelf_added_to_named, name.trim())

    val submit: () -> Unit = {
        if (canSubmit) {
            val trimmedName: String = name.trim()
            val trimmedDescription: String = description.trim()
            container.applicationScope.launch {
                if (shelfId != null) {
                    container.shelves.updateShelf(shelfId, trimmedName, trimmedDescription, visibility.raw)
                } else {
                    val owner: UserEntity = container.users.myUser() ?: return@launch
                    container.shelves.createShelf(
                        owner = owner,
                        name = trimmedName,
                        description = trimmedDescription,
                        visibility = visibility.raw,
                        itemIds = listOfNotNull(fileItemId),
                    )
                    if (fileItemId != null) messenger.show(addedTo)
                }
            }
            close()
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
                .navigationBarsPadding()
                .padding(horizontal = Spacing.medium)
                .padding(bottom = Spacing.medium),
            verticalArrangement = Arrangement.spacedBy(Spacing.medium),
        ) {
            SheetHeader(
                title = stringResource(if (isEditing) R.string.shelf_form_title_edit else R.string.shelf_form_title_new),
                closeLabel = stringResource(R.string.shelf_form_close),
                onClose = close,
            )
            FormTextField(
                value = name,
                onValueChange = { name = it },
                label = stringResource(R.string.shelf_form_name),
            )
            FormTextField(
                value = description,
                onValueChange = { description = it },
                label = stringResource(R.string.shelf_form_description),
                singleLine = false,
                minLines = 2,
                maxLines = 4,
            )
            WithLabel(label = stringResource(R.string.shelf_form_visibility)) {
                SingleChoiceSegmentedButtonRow(Modifier.fillMaxWidth()) {
                    ShelfVisibility.entries.forEachIndexed { index, option ->
                        SegmentedButton(
                            selected = visibility == option,
                            onClick = { visibility = option },
                            shape = SegmentedButtonDefaults.itemShape(index = index, count = ShelfVisibility.entries.size),
                            colors = SegmentedButtonDefaults.colors(
                                activeContainerColor = RecitTheme.colors.backgroundTinted,
                                activeContentColor = RecitTheme.colors.foregroundTinted,
                            ),
                        ) {
                            Text(stringResource(option.label), style = RecitTheme.typography.action200)
                        }
                    }
                }
            }
            PrimaryButton(
                text = stringResource(
                    when {
                        fileItemId != null -> R.string.shelf_form_create_and_add
                        isEditing -> R.string.shelf_form_save
                        else -> R.string.shelf_form_create
                    },
                ),
                onClick = submit,
                enabled = canSubmit,
            )
            if (isEditing) {
                DestructiveTextButton(
                    text = stringResource(R.string.shelf_form_delete),
                    onClick = { isConfirmingDelete = true },
                )
            }
        }
    }

    if (isConfirmingDelete && shelfId != null) {
        ConfirmDialog(
            title = stringResource(R.string.shelf_form_delete_confirm_title),
            message = stringResource(R.string.shelf_form_delete_confirm_message),
            confirmLabel = stringResource(R.string.action_delete),
            cancelLabel = stringResource(R.string.shelf_form_cancel),
            onConfirm = {
                isConfirmingDelete = false
                container.applicationScope.launch { container.shelves.deleteShelf(shelfId) }
                onDismiss()
                onDeleted()
            },
            onDismiss = { isConfirmingDelete = false },
        )
    }
}
