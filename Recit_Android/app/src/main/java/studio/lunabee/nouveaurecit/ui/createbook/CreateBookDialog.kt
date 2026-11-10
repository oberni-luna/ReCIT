package studio.lunabee.nouveaurecit.ui.createbook

import androidx.compose.runtime.Composable
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties

/**
 * Recherche's « Nouveau livre » (iOS feature 0087), full height above the tabs: the iOS sheet. The scanner
 * draws [CreateBookScreen] in place of its camera; Recherche has no camera to stand in for, so the flow
 * gets a window of its own, its pages and its back handling with it.
 *
 * Nothing closes it from outside: closing goes through [CreateBookScreen], which keeps a publication from
 * being left half-heard.
 */
@Composable
fun CreateBookDialog(session: CreateBookSession, onClose: () -> Unit) {
    Dialog(
        onDismissRequest = onClose,
        properties = DialogProperties(
            dismissOnBackPress = false,
            dismissOnClickOutside = false,
            usePlatformDefaultWidth = false,
            decorFitsSystemWindows = false,
        ),
    ) {
        CreateBookScreen(session = session, onClose = onClose)
    }
}
