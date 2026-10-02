package studio.lunabee.nouveaurecit.ui.lists

import androidx.compose.runtime.Composable

/**
 * `ListFormView`, as a sheet: create (`listId == null`), edit (`listId` set), or create a work list
 * and file one work in it (`fileWorkUri` set — no type picker then). [onDeleted] runs after the list
 * was deleted from the edit form.
 *
 * Placeholder until issue 0105 builds it; the signature is the contract other screens call.
 */
@Composable
fun ListFormSheet(
    listId: String?,
    fileWorkUri: String?,
    onDismiss: () -> Unit,
    onDeleted: () -> Unit = {},
) {
    onDismiss()
}
