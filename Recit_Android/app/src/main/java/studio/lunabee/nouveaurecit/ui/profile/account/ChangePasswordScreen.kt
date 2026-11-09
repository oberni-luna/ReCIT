package studio.lunabee.nouveaurecit.ui.profile.account

import android.content.Context
import androidx.activity.compose.BackHandler
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.auth.model.AuthFailure
import studio.lunabee.nouveaurecit.auth.model.PasswordResetOutcome
import studio.lunabee.nouveaurecit.data.user.PasswordChangeFailure
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.ui.common.LocalMessenger
import studio.lunabee.nouveaurecit.ui.common.Messenger
import studio.lunabee.nouveaurecit.ui.common.RecitTopBar
import studio.lunabee.nouveaurecit.ui.common.recitViewModel
import studio.lunabee.nouveaurecit.ui.editedition.FormActionBar
import studio.lunabee.nouveaurecit.ui.editedition.FormDivider
import studio.lunabee.nouveaurecit.ui.editedition.FormFootnote
import studio.lunabee.nouveaurecit.ui.editedition.FormSection
import studio.lunabee.nouveaurecit.ui.editedition.FormTextRow
import studio.lunabee.nouveaurecit.ui.editedition.SavingShield
import studio.lunabee.nouveaurecit.ui.navigation.Navigator

/**
 * `ChangePasswordView` (iOS feature 0055): « Mot de passe » — the current one, the new one, and
 * « Enregistrer », server first; a refusal is said under the fields, a success goes back to « Compte et
 * connexion » with a confirmation. Under them, « Mot de passe oublié ? » for the reader who changes it
 * because they no longer know it.
 */
@Composable
fun ChangePasswordScreen(navigator: Navigator) {
    val viewModel: ChangePasswordViewModel = recitViewModel { ChangePasswordViewModel(it) }
    val state: ChangePasswordUiState by viewModel.state.collectAsStateWithLifecycle()
    val messenger: Messenger = LocalMessenger.current
    val done: String = stringResource(R.string.change_password_done)

    LaunchedEffect(state.isSaved) {
        if (state.isSaved) {
            messenger.show(done)
            navigator.pop()
        }
    }
    BackHandler(enabled = state.isSaving) {}

    Scaffold(
        topBar = { RecitTopBar(title = stringResource(R.string.change_password_title), onBack = { if (!state.isSaving) navigator.pop() }) },
        bottomBar = {
            FormActionBar(
                text = stringResource(R.string.action_save),
                onClick = viewModel::save,
                enabled = state.canSave,
                isLoading = state.isSaving,
                modifier = Modifier.testTag("e2e.changePassword.save"),
            )
        },
        containerColor = RecitTheme.colors.backgroundForm,
    ) { padding: PaddingValues ->
        Box(Modifier.padding(padding).fillMaxSize()) {
            LazyColumn(
                modifier = Modifier.fillMaxSize().imePadding(),
                contentPadding = PaddingValues(top = Spacing.small, bottom = Spacing.large),
                verticalArrangement = Arrangement.spacedBy(Spacing.medium),
            ) {
                item(key = "passwords") {
                    PasswordsSection(state = state, viewModel = viewModel)
                }
                viewModel.email?.let { email: String ->
                    item(key = "forgot") {
                        ForgotPasswordSection(email = email, isRequesting = state.isRequestingReset, viewModel = viewModel)
                    }
                }
            }
            if (state.isSaving) SavingShield()
        }
    }
}

@Composable
private fun PasswordsSection(state: ChangePasswordUiState, viewModel: ChangePasswordViewModel) {
    val keyboard: KeyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password, autoCorrectEnabled = false)
    Column {
        FormSection(header = null, footer = null) {
            FormTextRow(
                label = stringResource(R.string.change_password_current),
                value = state.current,
                onValueChange = viewModel::setCurrent,
                keyboardOptions = keyboard,
                visualTransformation = PasswordVisualTransformation(),
                modifier = Modifier.testTag("e2e.changePassword.current"),
            )
            FormDivider()
            FormTextRow(
                label = stringResource(R.string.change_password_new),
                value = state.new,
                onValueChange = viewModel::setNew,
                keyboardOptions = keyboard,
                visualTransformation = PasswordVisualTransformation(),
                modifier = Modifier.testTag("e2e.changePassword.new"),
            )
        }
        Column(
            modifier = Modifier.padding(horizontal = Spacing.large, vertical = Spacing.small),
            verticalArrangement = Arrangement.spacedBy(Spacing.xSmall),
        ) {
            state.failure?.let { failure: PasswordChangeFailure.Reason ->
                FormFootnote(text = stringResource(failure.sentence), color = RecitTheme.colors.foregroundError)
            }
            FormFootnote(text = stringResource(R.string.change_password_footer))
        }
    }
}

/** « Mot de passe oublié ? », and where the link goes; the reset outcome is said in a snackbar. */
@Composable
private fun ForgotPasswordSection(email: String, isRequesting: Boolean, viewModel: ChangePasswordViewModel) {
    val messenger: Messenger = LocalMessenger.current
    val context: Context = LocalContext.current
    FormSection(header = null, footer = stringResource(R.string.change_password_forgot_footer, email)) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clickable(enabled = !isRequesting, role = Role.Button) {
                    viewModel.requestReset(email) { outcome: PasswordResetOutcome ->
                        val failure: AuthFailure? = outcome.failure
                        if (failure == null) {
                            messenger.show(context.getString(R.string.reset_sent_body, email))
                        } else {
                            messenger.showError(context.getString(failure.message))
                        }
                    }
                }
                .padding(horizontal = Spacing.medium, vertical = Spacing.sMedium)
                .testTag("e2e.changePassword.forgot"),
            horizontalArrangement = Arrangement.spacedBy(Spacing.small),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                text = stringResource(R.string.change_password_forgot),
                style = RecitTheme.typography.action300,
                color = if (isRequesting) RecitTheme.colors.foregroundDisable else RecitTheme.colors.foregroundTinted,
                modifier = Modifier.weight(1f),
            )
            if (isRequesting) {
                CircularProgressIndicator(
                    modifier = Modifier.size(Spacing.medium),
                    color = RecitTheme.colors.foregroundSecondary,
                    strokeWidth = 2.dp,
                )
            }
        }
    }
}
