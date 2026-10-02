package studio.lunabee.nouveaurecit.ui.auth

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.KeyboardType
import kotlinx.coroutines.launch
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.auth.model.PasswordResetOutcome
import studio.lunabee.nouveaurecit.designsystem.PrimaryButton
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.ui.common.LocalAppContainer
import studio.lunabee.nouveaurecit.ui.common.LocalMessenger

/** `ForgotPasswordView`, as a sheet. Every answer reads as the same confirmation (ADR 0008). */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ForgotPasswordSheet(onDismiss: () -> Unit) {
    val auth = LocalAppContainer.current.auth
    val messenger = LocalMessenger.current
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var email: String by rememberSaveable { mutableStateOf("") }
    var isSending: Boolean by rememberSaveable { mutableStateOf(false) }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true),
        containerColor = RecitTheme.colors.backgroundTinted,
    ) {
        Column(
            modifier = Modifier.padding(horizontal = Spacing.medium).padding(bottom = Spacing.large).navigationBarsPadding(),
            verticalArrangement = Arrangement.spacedBy(Spacing.large),
        ) {
            Text(stringResource(R.string.reset_title), style = RecitTheme.typography.title50, color = RecitTheme.colors.foregroundDefault)
            Text(stringResource(R.string.reset_lead), style = RecitTheme.typography.content300, color = RecitTheme.colors.foregroundDefault)
            AuthField(
                label = stringResource(R.string.signup_email),
                value = email,
                onValueChange = { email = it },
                keyboardType = KeyboardType.Email,
            )
            PrimaryButton(
                text = stringResource(R.string.reset_button_send),
                enabled = email.isNotBlank(),
                isLoading = isSending,
                onClick = {
                    isSending = true
                    scope.launch {
                        val address: String = email.trim()
                        val outcome: PasswordResetOutcome = auth.requestPasswordReset(address)
                        isSending = false
                        val failure = outcome.failure
                        if (failure == null) {
                            messenger.show(context.getString(R.string.reset_sent_title), context.getString(R.string.reset_sent_body, address))
                            onDismiss()
                        } else {
                            messenger.showError(context.getString(failure.message))
                        }
                    }
                },
            )
        }
    }
}

