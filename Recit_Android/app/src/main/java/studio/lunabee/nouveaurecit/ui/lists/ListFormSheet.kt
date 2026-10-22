package studio.lunabee.nouveaurecit.ui.lists

import android.content.Context
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuAnchorType
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.SheetState
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.async
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import studio.lunabee.nouveaurecit.AppContainer
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.db.ListWithElements
import studio.lunabee.nouveaurecit.data.model.EntityListType
import studio.lunabee.nouveaurecit.data.model.Visibility
import studio.lunabee.nouveaurecit.designsystem.DestructiveTextButton
import studio.lunabee.nouveaurecit.designsystem.FormTextField
import studio.lunabee.nouveaurecit.designsystem.PrimaryButton
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.SheetHeader
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.ui.common.LocalAppContainer
import studio.lunabee.nouveaurecit.ui.common.LocalMessenger
import studio.lunabee.nouveaurecit.ui.common.Messenger

/**
 * `ListFormView`, as a sheet: create (`listId == null`), edit (`listId` set), or create a work list
 * and file one work in it (`fileWorkUri` set — no type picker then). [onDeleted] runs after the list
 * was deleted from the edit form.
 *
 * Every write is server-first and runs in the application scope, so closing the sheet mid-request
 * stops the waiting, not the write. A failure keeps the sheet open with what was typed.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ListFormSheet(
    listId: String?,
    fileWorkUri: String?,
    onDismiss: () -> Unit,
    onDeleted: () -> Unit = {},
) {
    val container: AppContainer = LocalAppContainer.current
    val messenger: Messenger = LocalMessenger.current
    val context: Context = LocalContext.current
    val scope: CoroutineScope = rememberCoroutineScope()
    val sheetState: SheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)

    val isCreating: Boolean = listId == null
    val isFiling: Boolean = fileWorkUri != null
    var name: String by rememberSaveable { mutableStateOf("") }
    var description: String by rememberSaveable { mutableStateOf("") }
    var type: EntityListType by rememberSaveable { mutableStateOf(EntityListType.Work) }
    var visibility: List<Visibility> by remember { mutableStateOf(emptyList()) }
    var isSeeded: Boolean by rememberSaveable { mutableStateOf(false) }
    var isSubmitting: Boolean by remember { mutableStateOf(false) }
    var isDeleting: Boolean by remember { mutableStateOf(false) }

    LaunchedEffect(listId) {
        if (listId == null) return@LaunchedEffect
        val existing: ListWithElements = container.lists.observeList(listId).first() ?: return@LaunchedEffect
        visibility = existing.list.visibility
        if (!isSeeded) {
            name = existing.list.name
            description = existing.list.explanation
            type = existing.list.type
            isSeeded = true
        }
    }

    fun showError(error: Throwable) {
        messenger.showError(context.getString(R.string.error_generic), error.localizedMessage)
    }

    fun submit() {
        if (isSubmitting) return
        isSubmitting = true
        scope.launch {
            val result: Result<Unit> = runCatching {
                container.applicationScope.async {
                    when {
                        fileWorkUri != null -> {
                            container.lists.createListAndAddWork(name, description, fileWorkUri)
                            messenger.show(context.getString(R.string.list_added_to_named, name.trim()))
                        }
                        listId == null -> container.lists.createList(name, description, type, emptyList())
                        else -> container.lists.updateList(listId, name, description, visibility)
                    }
                    Unit
                }.await()
            }
            isSubmitting = false
            result.onSuccess { onDismiss() }.onFailure(::showError)
        }
    }

    fun delete() {
        if (listId == null || isDeleting) return
        isDeleting = true
        scope.launch {
            val result: Result<Unit> = runCatching { container.applicationScope.async { container.lists.deleteList(listId) }.await() }
            isDeleting = false
            result
                .onSuccess {
                    onDismiss()
                    onDeleted()
                }
                .onFailure(::showError)
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
                title = stringResource(if (isCreating) R.string.list_form_create_title else R.string.list_form_edit_title),
                closeLabel = stringResource(R.string.action_close),
                onClose = onDismiss,
            )
            FormTextField(
                value = name,
                onValueChange = { name = it },
                label = stringResource(R.string.list_form_name),
            )
            FormTextField(
                value = description,
                onValueChange = { description = it },
                label = stringResource(R.string.list_form_description),
                singleLine = false,
                minLines = 2,
                maxLines = 4,
            )

            // Not asked when the book has already answered: a list opened from a book holds its work.
            if (isCreating && !isFiling) {
                ListTypePicker(selected = type, onSelect = { type = it })
            }

            PrimaryButton(
                text = stringResource(
                    when {
                        isFiling -> R.string.list_form_create_and_add
                        isCreating -> R.string.list_form_create
                        else -> R.string.action_save
                    },
                ),
                onClick = ::submit,
                enabled = ListsPresentation.canSubmit(isFiling, name) && !isDeleting,
                isLoading = isSubmitting,
            )
            if (!isCreating) {
                DestructiveTextButton(
                    text = stringResource(R.string.list_form_delete),
                    onClick = ::delete,
                    enabled = !isSubmitting,
                    isLoading = isDeleting,
                )
            }
        }
    }
}

/** `Picker("list.form.type")` over the three types, as a menu. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ListTypePicker(selected: EntityListType, onSelect: (EntityListType) -> Unit) {
    var expanded: Boolean by remember { mutableStateOf(false) }
    ExposedDropdownMenuBox(expanded = expanded, onExpandedChange = { expanded = it }) {
        FormTextField(
            value = stringResource(selected.label),
            onValueChange = {},
            label = stringResource(R.string.list_form_type),
            readOnly = true,
            trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded) },
            modifier = Modifier.menuAnchor(ExposedDropdownMenuAnchorType.PrimaryNotEditable),
        )
        ExposedDropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
            EntityListType.entries.forEach { type ->
                DropdownMenuItem(
                    text = { Text(stringResource(type.label), style = RecitTheme.typography.content300) },
                    onClick = {
                        onSelect(type)
                        expanded = false
                    },
                )
            }
        }
    }
}
