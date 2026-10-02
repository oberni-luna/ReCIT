package studio.lunabee.nouveaurecit.ui.profile

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.pluralStringResource
import androidx.compose.ui.res.stringResource
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import studio.lunabee.nouveaurecit.R
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
        containerColor = RecitTheme.colors.backgroundSecondary,
    ) { padding: PaddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(Spacing.large),
            verticalArrangement = Arrangement.spacedBy(Spacing.large),
        ) {
            BodyText(stringResource(R.string.delete_account_intro))

            summary?.let { counted: AccountDeletionSummary ->
                if (counted.isEmpty) {
                    BodyText(stringResource(R.string.delete_account_empty))
                } else {
                    Column(verticalArrangement = Arrangement.spacedBy(Spacing.small)) {
                        counted.lines.forEach { line: AccountDeletionSummary.Line -> BodyText(lineText(line)) }
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
        AlertDialog(
            onDismissRequest = { isConfirming = false },
            title = { Text(stringResource(R.string.delete_account_confirm_title)) },
            text = { Text(stringResource(R.string.delete_account_confirm_message)) },
            dismissButton = {
                TextButton(onClick = { isConfirming = false }) {
                    Text(stringResource(R.string.action_cancel))
                }
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        isConfirming = false
                        viewModel.deleteAccount { error: Throwable -> messenger.showError(genericError, error.localizedMessage) }
                    },
                ) {
                    Text(stringResource(R.string.delete_account_confirm_delete), color = RecitTheme.colors.foregroundError)
                }
            },
            containerColor = RecitTheme.colors.backgroundDefault,
            titleContentColor = RecitTheme.colors.foregroundDefault,
            textContentColor = RecitTheme.colors.foregroundDefault,
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

@Composable
private fun BodyText(text: String) {
    Text(text = text, style = RecitTheme.typography.content300, color = RecitTheme.colors.foregroundDefault)
}

@Composable
private fun SecondaryText(text: String) {
    Text(text = text, style = RecitTheme.typography.content300, color = RecitTheme.colors.foregroundSecondary)
}
