package studio.lunabee.nouveaurecit.ui.inventory

import androidx.compose.runtime.Composable

/**
 * `ShelfFormView`, as a sheet: create (`shelfId == null`), edit (`shelfId` set), or create and file
 * one copy in it (`fileItemId` set). [onDeleted] runs after the shelf was deleted from the edit form.
 *
 * Placeholder until issue 0103 builds it; the signature is the contract other screens call.
 */
@Composable
fun ShelfFormSheet(
    shelfId: String?,
    fileItemId: String?,
    onDismiss: () -> Unit,
    onDeleted: () -> Unit = {},
) {
    onDismiss()
}
