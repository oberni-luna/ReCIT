package studio.lunabee.nouveaurecit.ui.profile

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.LibraryBooks
import androidx.compose.material.icons.automirrored.outlined.List
import androidx.compose.material.icons.automirrored.outlined.MenuBook
import androidx.compose.material3.Icon
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.pluralStringResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.designsystem.ConfirmDialog
import studio.lunabee.nouveaurecit.designsystem.DestructiveButton
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.ui.common.LocalMessenger
import studio.lunabee.nouveaurecit.ui.common.Messenger
import studio.lunabee.nouveaurecit.ui.common.RecitTopBar
import studio.lunabee.nouveaurecit.ui.common.recitViewModel
import studio.lunabee.nouveaurecit.ui.navigation.Navigator

/**
 * `DeleteAccountView`: the screen between the Profil's last row and an account that no longer
 * exists. It says what will be lost, counted ([AccountDeletionSummary]); only the button at its foot
 * raises the dialog that acts.
 *
 * On success the root swaps to the welcome screen by itself. On failure the screen stays up, its
 * button live, and the reason goes in a snackbar. The transactions line and its warning are not
 * ported (transactions are not on Android).
 */
@Composable
fun DeleteAccountScreen(navigator: Navigator) {
    val viewModel: DeleteAccountViewModel = recitViewModel { container -> DeleteAccountViewModel(container) }
    val summary: AccountDeletionSummary? by viewModel.summary.collectAsStateWithLifecycle()
    val isDeleting: Boolean by viewModel.isDeleting.collectAsStateWithLifecycle()
    var isConfirming: Boolean by rememberSaveable { mutableStateOf(false) }
    val messenger: Messenger = LocalMessenger.current
    val genericError: String = stringResource(R.string.error_generic)

    Scaffold(
        topBar = { RecitTopBar(title = stringResource(R.string.delete_account_title), onBack = navigator::pop) },
        containerColor = RecitTheme.colors.backgroundDefault,
    ) { padding: PaddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = Spacing.medium, vertical = Spacing.large),
            verticalArrangement = Arrangement.spacedBy(Spacing.large),
        ) {
            BodyText(stringResource(R.string.delete_account_intro))

            summary?.let { counted: AccountDeletionSummary ->
                if (counted.isEmpty) {
                    BodyText(stringResource(R.string.delete_account_empty))
                } else {
                    Column(verticalArrangement = Arrangement.spacedBy(Spacing.small)) {
                        counted.lines.forEach { line: AccountDeletionSummary.Line -> LossLine(lineText(line), lineIcon(line)) }
                    }
                }
            }

            Column(verticalArrangement = Arrangement.spacedBy(Spacing.small)) {
                SecondaryText(stringResource(R.string.delete_account_hosting))
                SecondaryText(stringResource(R.string.delete_account_username_kept))
            }

            DestructiveButton(
                text = stringResource(R.string.delete_account_button),
                onClick = { isConfirming = true },
                modifier = Modifier.fillMaxWidth(),
                enabled = !isDeleting,
                isLoading = isDeleting,
            )
        }
    }

    if (isConfirming) {
        ConfirmDialog(
            title = stringResource(R.string.delete_account_confirm_title),
            message = stringResource(R.string.delete_account_confirm_message),
            confirmLabel = stringResource(R.string.delete_account_confirm_delete),
            cancelLabel = stringResource(R.string.action_cancel),
            onConfirm = {
                isConfirming = false
                viewModel.deleteAccount { error: Throwable -> messenger.showError(genericError, error.localizedMessage) }
            },
            onDismiss = { isConfirming = false },
        )
    }
}

@Composable
private fun lineText(line: AccountDeletionSummary.Line): String {
    val plural: Int = when (line.kind) {
        AccountDeletionSummary.Kind.Books -> R.plurals.delete_account_line_books
        AccountDeletionSummary.Kind.Shelves -> R.plurals.delete_account_line_shelves
        AccountDeletionSummary.Kind.Lists -> R.plurals.delete_account_line_lists
    }
    return pluralStringResource(plural, line.count, line.count)
}

/** One thing the deletion takes away, behind the glyph of what it is. */
@Composable
private fun LossLine(text: String, icon: ImageVector) {
    Row(horizontalArrangement = Arrangement.spacedBy(Spacing.sMedium), verticalAlignment = Alignment.CenterVertically) {
        Icon(icon, contentDescription = null, tint = RecitTheme.colors.foregroundError, modifier = Modifier.size(20.dp))
        BodyText(text)
    }
}

private fun lineIcon(line: AccountDeletionSummary.Line): ImageVector = when (line.kind) {
    AccountDeletionSummary.Kind.Books -> Icons.AutoMirrored.Outlined.MenuBook
    AccountDeletionSummary.Kind.Shelves -> Icons.AutoMirrored.Outlined.LibraryBooks
    AccountDeletionSummary.Kind.Lists -> Icons.AutoMirrored.Outlined.List
}

@Composable
private fun BodyText(text: String) {
    Text(text = text, style = RecitTheme.typography.content300, color = RecitTheme.colors.foregroundDefault)
}

@Composable
private fun SecondaryText(text: String) {
    Text(text = text, style = RecitTheme.typography.content300, color = RecitTheme.colors.foregroundSecondary)
}
