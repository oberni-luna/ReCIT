package studio.lunabee.nouveaurecit.ui.profile.account

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.Scaffold
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.input.KeyboardType
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.auth.model.AuthFailure
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.ui.common.LocalMessenger
import studio.lunabee.nouveaurecit.ui.common.Messenger
import studio.lunabee.nouveaurecit.ui.common.RecitTopBar
import studio.lunabee.nouveaurecit.ui.common.recitViewModel
import studio.lunabee.nouveaurecit.ui.editedition.EditionPropertyRow
import studio.lunabee.nouveaurecit.ui.editedition.FormActionBar
import studio.lunabee.nouveaurecit.ui.editedition.FormDivider
import studio.lunabee.nouveaurecit.ui.editedition.FormFootnote
import studio.lunabee.nouveaurecit.ui.editedition.FormSection
import studio.lunabee.nouveaurecit.ui.editedition.FormTextRow
import studio.lunabee.nouveaurecit.ui.editedition.PropertyRowTrailing
import studio.lunabee.nouveaurecit.ui.editedition.SavingShield
import studio.lunabee.nouveaurecit.ui.navigation.Navigator

/**
 * `ChangeEmailView` (iOS feature 0055): « Adresse e-mail » — the address in use, the new one checked while
 * it is typed as at sign-up, and « Enregistrer », server first. inventaire.io then mails a link to the new
 * address and holds it unconfirmed until it is opened; « Compte et connexion » says so.
 */
@Composable
fun ChangeEmailScreen(navigator: Navigator) {
    val viewModel: ChangeEmailViewModel = recitViewModel { ChangeEmailViewModel(it) }
    val state: ChangeEmailUiState by viewModel.state.collectAsStateWithLifecycle()
    val messenger: Messenger = LocalMessenger.current
    val genericError: String = stringResource(R.string.error_generic)
    val done: String? = state.savedAddress?.let { stringResource(R.string.change_email_done, it) }

    LaunchedEffect(done) {
        if (done != null) {
            messenger.show(done)
            navigator.pop()
        }
    }
    BackHandler(enabled = state.isSaving) {}

    Scaffold(
        topBar = { RecitTopBar(title = stringResource(R.string.change_email_title), onBack = { if (!state.isSaving) navigator.pop() }) },
        bottomBar = {
            FormActionBar(
                text = stringResource(R.string.action_save),
                onClick = { viewModel.save { error: Throwable -> messenger.showError(genericError, error.localizedMessage) } },
                enabled = state.canSave,
                isLoading = state.isSaving,
                modifier = Modifier.testTag("e2e.changeEmail.save"),
            )
        },
        containerColor = RecitTheme.colors.backgroundForm,
    ) { padding: PaddingValues ->
        Box(Modifier.padding(padding).fillMaxSize()) {
            LazyColumn(
                modifier = Modifier.fillMaxSize().imePadding(),
                contentPadding = PaddingValues(top = Spacing.small, bottom = Spacing.large),
            ) {
                item(key = "address") {
                    FormSection(header = null, footer = null) {
                        state.current?.let { current: String ->
                            EditionPropertyRow(
                                label = stringResource(R.string.change_email_current),
                                value = current,
                                placeholder = "",
                                trailing = PropertyRowTrailing.None,
                            )
                            FormDivider()
                        }
                        FormTextRow(
                            label = stringResource(R.string.change_email_new),
                            value = state.email,
                            onValueChange = viewModel::setEmail,
                            keyboardOptions = KeyboardOptions(
                                capitalization = KeyboardCapitalization.None,
                                autoCorrectEnabled = false,
                                keyboardType = KeyboardType.Email,
                            ),
                            modifier = Modifier.testTag("e2e.changeEmail.new"),
                        )
                    }
                }
                item(key = "footer") {
                    Column(
                        modifier = Modifier.padding(horizontal = Spacing.large, vertical = Spacing.small),
                        verticalArrangement = Arrangement.spacedBy(Spacing.xSmall),
                    ) {
                        state.failure?.let { failure: AuthFailure ->
                            FormFootnote(text = stringResource(failure.message), color = RecitTheme.colors.foregroundError)
                        }
                        FormFootnote(text = stringResource(R.string.change_email_footer))
                    }
                }
            }
            if (state.isSaving) SavingShield()
        }
    }
}
